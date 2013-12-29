//
//  Server.m
//  iServe
//
//  Created by Mirza Kapetanovic on 9/27/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "ISServer.h"

#import "ISRouterDelegate.h"
#import "HttpServer.h"

#import "ISAlbum.h"
#import "ISFile.h"

#import "NSDictionary+ISCollection.h"
#import "NSArray+ISCollection.h"
#import "NSData+ISData.h"

#import "ISAction.h"
#import "ISMimeTypes.h"

#define HTTP_ERROR(response, error, resource) \
    if(error) { [response sendError:error]; return; } \
    if(!resource) { [response sendNotFound:@"Resource not found"]; return; } \

const NSUInteger DATA_BUFFER_LENGTH = 1024 * 1024;
const NSUInteger CACHING_TIME = 60 * 60 * 24 * 365;

BOOL IsNullOrEmpty(id obj) {
    if(!obj || obj == [NSNull null]) {
        return YES;
    }
    if([obj isKindOfClass:[NSString class]]) {
        return [obj isEqualToString:@""];
    }
    
    return NO;
}

NSString *AssetsPath(NSString *path) {
    NSString *assetsPath = [[NSBundle mainBundle] resourcePath];
    return [assetsPath stringByAppendingPathComponent:path];
}

NSString *AbsoluteUrl(HttpServerRequest *request, NSString *path, NSDictionary *query) {
    NSString *host = [request.header fieldValue:@"Host"];
    
    if(query && [query count]) {
        path = [NSString stringWithFormat:@"%@?%@", path, SerializeQuery(query)];
    }
    if(!host) {
        return path;
    }
    
    return [NSString stringWithFormat:@"http://%@%@", host, path];
}

NSDictionary *SerializeDirectory(NSString *path, BOOL hidden, NSError **error) {
    NSFileManager *fs = [NSFileManager defaultManager];
    NSError *fsError = nil;
    NSMutableDictionary *directory = [NSMutableDictionary dictionary];
    
    NSArray *files = [fs contentsOfDirectoryAtPath:path error:&fsError];
    
    if(fsError) {
        if(error != NULL) *error = fsError;
        return nil;
    }
    
    for (NSString* fileName in files) {
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        
        if(!hidden && [filePath hasPrefix:@"."]) {
            continue;
        }
        
        BOOL isDirectory = NO;
        [fs fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        id content = nil;
        
        if(isDirectory) {
            content = SerializeDirectory(filePath, hidden, &fsError);
        } else {
            content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&fsError];
        }
        
        if(fsError) {
            if(error != NULL) *error = fsError;
            return nil;
        }
        
        [directory setValue:content forKey:fileName];
    }
    
    return directory;
}

NSArray *SerializeResources(NSString *path, NSError **error) {
    NSError *err = nil;
    NSString *resources = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    if(err) {
        if(error != NULL) *error = err;
        return nil;
    }
    
    NSArray *list = [resources componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSString* resource in list) {
        resource = [resource stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if(resource.length) {
            [result addObject:resource];
        }
    }
    
    return result;
}

void StreamJavascript(HttpServerResponse *response, NSString *var, id object) {
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    
    if(error) {
        [response sendError:error];
        return;
    }
    
    NSMutableData *body = [[var dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    uint8_t assign[3] = { 0x20, 0x3D, 0x20 };
    
    [body appendBytes:&assign length:3];
    [body appendData:json];
    
    [response.header setValue:@"application/javascript" forField:@"Content-Type"];
    [response sendData:body];
    
    [body release];
}

void StreamFileData(HttpServerResponse *response, ISFile *file, NSUInteger offset) {
    NSUInteger length = [file getDataLength];
    BOOL flushed = NO;

    do {
        NSUInteger read = length - offset < DATA_BUFFER_LENGTH ? length - offset : DATA_BUFFER_LENGTH;
        NSData *buffer = [file getDataFromOffset:offset length:read];
        
        if(!buffer) {
            [response.connection destroy];
            return;
        }
        
        flushed = [response write:buffer];
        offset += read;
    } while(flushed && offset < length);
    
    HttpServerResponseBlockDelegate *delegate = response.delegate;
    
    if(offset < length) {
        delegate.drain = ^(HttpServerResponse *response) {
            StreamFileData(response, file, offset);
        };
    } else {
        delegate.drain = nil;
        [response end];
    }
}

@implementation ISServer {
    ISRouterDelegate *_router;
    HttpServer *_server;
    
    ISMimeTypes *_mimeTypes;
    NSPredicate *_charset;
    NSString *_cache;
    
    ALAssetsLibrary *_assetsLibrary;
}

@synthesize delegate = _delegate;

-(id) init {
    if(self = [super init]) {
        _router = [[ISRouterDelegate alloc] init];
        _server = [[HttpServer alloc] init];
        
        _mimeTypes = [[ISMimeTypes alloc] initWithJsonFile:AssetsPath(@"mimetypes.json")];
        _charset = [[NSPredicate predicateWithFormat:@"(SELF BEGINSWITH \"text/\") AND NOT (SELF LIKE \"*charset=*\")"] retain];
        _cache = [[[[[NSDate date] description] dataUsingEncoding:NSUTF8StringEncoding] sha1] hexEncode];
        
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        
        _server.delegate = _router;
        
        _router.error = ^(ISRouterDelegate *router, NSError *error) {
            if(self.delegate) [self.delegate server:self errorOccurred:error];
        };
        _router.close = ^(ISRouterDelegate *router) {
            if(self.delegate) [self.delegate serverDidClose:self];
        };
        
        [_router matchMethod:@"GET" path:@"/api/albums" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getAlbums:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/api/albums/thumbnail"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getAlbumThumbnail:request response:response];
        }];
        
        [_router matchMethod:@"GET" path:@"/api/files" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getFiles:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/api/files/thumbnail"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getFileThumbnail:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/api/files/image"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getFileImage:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/api/files/data"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getFileData:request response:response];
        }];
        
        [_router matchMethod:@"GET" path:@"/public/templates"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getTemplates:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/public/scripts"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getScripts:request response:response];
        }];
        [_router matchMethod:@"GET" path:@"/public/styles"
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getStyles:request response:response];
        }];
        
        [_router matchMethod:@"GET" path:@[@"/app/*", @"/app"]
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            HttpUrl *url = [[HttpUrl alloc] initWithPathname:@"/public/index.html" query:request.header.url.query];
            request.header.url = url;
            [url release];
            
            [response setCookieWithName:@"cache" value:_cache];
            [self getPublicFiles:request response:response];
            
        }];
        [_router matchMethod:@"GET" path:@"/" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [response redirectToLocation:AbsoluteUrl(request, @"/app", nil)];
            [response end];
        }];
        
        [_router matchMethod:@"GET" path:@"/*" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getPublicFiles:request response:response];
        }];
    }
    
    return self;
}

-(void) getPublicFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    NSString *path = request.header.url.pathname;
    NSData *file = [NSData dataWithContentsOfFile:AssetsPath(path)];
    
    if(!file) {
        [response sendString:[NSString stringWithFormat:@"%@ not found", path] statusCode:HttpStatusCodeNotFound];
        return;
    }
    
    NSString *mimeType = [_mimeTypes mimeTypeForExtensionWithFallback:[path pathExtension]];
    
    if([_charset evaluateWithObject:mimeType]) {
        mimeType = [mimeType stringByAppendingString:@"; charset=utf-8"];
    }
    
    [response cache:CACHING_TIME];
    [response.header setValue:mimeType forField:@"Content-Type"];
    [response sendData:file];
}

-(void) getTemplates:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSError *error = nil;
    NSDictionary *directory = SerializeDirectory(AssetsPath(@"/public/templates"), NO, &error);
    
    if(error) {
        [response sendError:error];
        return;
    }
    
    [response cache:CACHING_TIME];
    
    StreamJavascript(response, @"window._templates", directory);
}

-(void) getScripts:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSError *error = nil;
    NSArray *scripts = SerializeResources(AssetsPath(@"/public/scripts.txt"), &error);
    
    if(error) {
        [response sendError:error];
        return;
    }
    
    StreamJavascript(response, @"window._scripts", scripts);
}

-(void) getStyles:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    NSError *error = nil;
    NSArray *styles = SerializeResources(AssetsPath(@"/public/styles.txt"), &error);
    
    if(error) {
        [response sendError:error];
        return;
    }
    
    StreamJavascript(response, @"window._styles", styles);
}

-(void) getAlbums:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    [ISAlbum getAllUsingAssetsLibrary:_assetsLibrary block:^(NSArray *albums, NSError *error) {
        HTTP_ERROR(response, error, albums);
        
        albums = [albums mapObjectsUsingBlock:^(ISAlbum *album, NSUInteger i) {
            NSDictionary *query = @{ @"album": album.url };
            
            return [album toDictionary:@{
                @"files": AbsoluteUrl(request, @"/api/files", query),
                @"thumbnail": AbsoluteUrl(request, @"/api/albums/thumbnail", query)
            }];
        }];
        
        [response sendJson:albums];
    }];
}

-(void) getFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    NSString *albumUrl = [request.header.url.query objectForKey:@"album"];
    
    if(IsNullOrEmpty(albumUrl)) {
        [response sendBadRequest:@"Invalid parameter"];
        return;
    }
    
    [ISFile getAllUsingAssetsLibrary:_assetsLibrary byAlbumUrl:albumUrl block:^(NSArray *files, NSError *error) {
        HTTP_ERROR(response, error, files);
     
        files = [files mapObjectsUsingBlock:^(ISFile *file, NSUInteger i) {
            NSDictionary *query = @{ @"file": file.url };
            
            return [file toDictionary:@{
                @"thumbnail": AbsoluteUrl(request, @"/api/files/thumbnail", query),
                @"image": AbsoluteUrl(request, @"/api/files/image", query),
                @"data": AbsoluteUrl(request, @"/api/files/data", query),
                @"download": AbsoluteUrl(request, @"/api/files/data",
                                         [query mergeWithEntriesFromDictionary:@{ @"download" : @"1" }])
            }];
        }];
     
        [response sendJson:files];
    }];
}

-(void) getAlbumThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSString *albumUrl = [request.header.url.query objectForKey:@"album"];
    
    if(IsNullOrEmpty(albumUrl)) {
        [response sendBadRequest:@"Invalid parameter"];
        return;
    }
    
    [ISAlbum getUsingAssetsLibrary:_assetsLibrary byUrl:albumUrl block:^(ISAlbum *album, NSError *error) {
        HTTP_ERROR(response, error, album);
        
        NSInteger count = [album numberOfFiles];
        
        if(!count) {
            [response sendData:nil];
            return;
        }
        
        [album getFileByIndex:(count - 1) block:^(ISFile *file, NSError *error) {
            HTTP_ERROR(response, error, file);
            
            [response.header setValue:ISImageGetRepresentationMimeType(ISImageRepresentationPNG) forField:@"Content-Type"];
            [response sendData:[file getThumbnail:ISImageRepresentationPNG]];
        }];
    }];
}

-(void) getFileThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    [self streamImage:request response:response block:^(ISFile *file, ISImageRepresentation representation) {
        return [file getThumbnail:representation];
    }];
}

-(void) getFileImage:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    [self streamImage:request response:response block:^(ISFile *file, ISImageRepresentation representation) {
        return [file getImage:representation];
    }];
}

-(void) getFileData:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSString *fileUrl = [request.header.url.query valueForKey:@"file"];
    
    if(IsNullOrEmpty(fileUrl)) {
        [response sendBadRequest:@"Invalid parameter"];
        return;
    }
    
    [ISFile getUsingAssetsLibrary:_assetsLibrary byUrl:fileUrl block:^(ISFile *file, NSError *error) {
        HTTP_ERROR(response, error, file);
        
        if([request.header.url.query objectForKey:@"download"]) {
            [response.header setValue:[NSString stringWithFormat:@"attachment; filename=\"%@\"", file.name]
                        forField:@"Content-Disposition"];
        }
        
        [response cache:CACHING_TIME];
        
        [response executeOnCallerThread:^{
            [response writeHeaderStatus:HttpStatusCodeOk headers:@{
                @"Content-Type": [_mimeTypes mimeTypeForExtension:file.extension],
                @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)[file getDataLength]]
            }];
            
            StreamFileData(response, file, 0);
        }];
    }];
}

-(void) close {
    [_server close];
}

-(void) listenOnPort:(NSInteger)port {
    [_server listenOnPort:port];
}

-(void) dealloc {
    _server.delegate = nil;
    
    [_router release];
    [_server release];
    [_mimeTypes release];
    [_charset release];
    [_cache release];
    [_assetsLibrary release];
    
    [super dealloc];
}

-(void) streamImage:(HttpServerRequest *)request response:(HttpServerResponse *)response
             block:(NSData* (^)(ISFile*, ISImageRepresentation))block {
    NSString *fileUrl = [request.header.url.query valueForKey:@"file"];
    
    if(IsNullOrEmpty(fileUrl)) {
        [response sendBadRequest:@"Invalid parameter"];
        return;
    }
    
    [ISFile getUsingAssetsLibrary:_assetsLibrary byUrl:fileUrl block:^(ISFile *file, NSError *error) {
        HTTP_ERROR(response, error, file);
        
        [response.header setValue:ISImageGetRepresentationMimeType(ISImageRepresentationPNG) forField:@"Content-Type"];
        [response cache:CACHING_TIME];
        
        [response sendData:block(file, ISImageRepresentationPNG)];
    }];
}
@end

@implementation ISThreadedServerDelegate {
    NSThread *_caller;
}

@synthesize delegate = _delegate;

-(id) init {
    return [self initWithThread:[NSThread currentThread]];
}

-(id) initWithThread:(NSThread *)caller {
    if(self = [super init]) {
        self->_caller = [caller retain];
        self->_delegate = nil;
    }
    
    return self;
}

-(void) serverDidClose:(ISServer *)server {
    if(self.delegate) {
        [ISAction executeBlockOnThread:_caller waitUntilDone:NO block:^{
            [self.delegate serverDidClose:server];
        }];
    }
}

-(void) server:(ISServer *)server errorOccurred:(NSError *)error {
    if(self.delegate) {
        [ISAction executeBlockOnThread:_caller waitUntilDone:NO block:^{
            [self.delegate server:server errorOccurred:error];
        }];
    }
}

-(void) dealloc {
    _delegate = nil;
    [_caller release];
    
    [super dealloc];
}
@end

@implementation ISThreadedServer {
    ISServer *_server;
    ISThreadedServerDelegate *_delegate;
    
    volatile NSInteger _port;
}

-(id) init {
    if(self = [super init]) {
        self->_delegate = [[ISThreadedServerDelegate alloc] init];
        
        [self setName:@"ISThreadedServer"];
    }
    
    return self;
}

-(id <ISServerDelegate>) delegate {
    @synchronized(_delegate) {
        return _delegate.delegate;
    }
}

-(void) setDelegate:(id <ISServerDelegate>)delegate {
    @synchronized(_delegate) {
        _delegate.delegate = delegate;
    }
}

-(void) main {
    @autoreleasepool {
        _server = [[ISServer alloc] init];
        _server.delegate = _delegate;
        
        [_server listenOnPort:_port];
        
        CFRunLoopRun();
    }
}

-(void) close {
    [ISAction executeBlockOnThread:self waitUntilDone:YES block:^{
        [_server close];
        
        CFRunLoopRef current = CFRunLoopGetCurrent();
        CFRunLoopStop(current);
    }];
}

-(void) listenOnPort:(NSInteger)port {
    _port = port;
    [self start];
}

-(void) dealloc {
    _server.delegate = nil;
    
    [_server release];
    [_delegate release];
    
    [super dealloc];
}
@end
