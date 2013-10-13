//
//  Server.m
//  iServe
//
//  Created by Mirza Kapetanovic on 9/27/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "ISServer.h"

#import "HttpServerRouterDelegate.h"
#import "HttpServer.h"

#import "ISAlbum.h"
#import "ISFile.h"

#import "NSDictionary+ISCollection.h"
#import "NSArray+ISCollection.h"
#import "ISMimeTypes.h"

#define HTTP_ERROR(resource) \
    if(PermissionError(response, error) || ServerError(response, error) || ResourceNotFound(response, resource)) return;

const NSUInteger DATA_BUFFER_LENGTH = 1024 * 1024;

NSString *AssetsPath(NSString *path) {
    NSString *assetsPath = [[NSBundle mainBundle] resourcePath];
    return [assetsPath stringByAppendingPathComponent:path];
}

NSString *AbsoluteUrl(HttpServerRequest *request, NSString *path, NSDictionary *query) {
    NSString *host = [request.header fieldValue:@"Host"];
    
    if(!host) {
        return nil;
    }
    
    NSString *url = [NSString stringWithFormat:@"http://%@%@", host, path];
    
    if(query && [query count]) {
        return [url stringByAppendingFormat:@"?%@", SerializeQuery(query)];
    }
    
    return url;
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

void RenderData(HttpServerResponse *response, HttpStatusCode status, NSData *body) {
    NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    
    [response writeHeaderStatus:status headers:@{ @"Content-Length": length }];
    [response write:body];
    [response end];
}

void RenderString(HttpServerResponse *response, HttpStatusCode status, NSString *body) {
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    if(![response.header fieldValue:@"Content-Type"]) {
        [response.header setValue:@"text/plain; charset=utf-8" forField:@"Content-Type"];
    }
    
    RenderData(response, status, data);
}

void RenderJson(HttpServerResponse *response, HttpStatusCode status, id body) {
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    
    if(ServerError(response, error)) {
        return;
    }

    [response.header setValue:@"application/json" forField:@"Content-Type"];
    RenderData(response, status, json);
}

void StreamFileData(HttpServerResponse *response, ISFile *file, NSUInteger offset) {
    NSUInteger length = [file getDataLength];
    BOOL flushed = NO;

    do {
        NSUInteger read = length - offset < DATA_BUFFER_LENGTH ? length - offset : DATA_BUFFER_LENGTH;
        NSData *buffer = [file getDataFromOffset:offset length:read];
        
        if(!buffer) {
            [response.connection close];
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

BOOL PermissionError(HttpServerResponse *response, NSError *error) {
    if(error && [[error domain] isEqualToString:ALAssetsLibraryErrorDomain]) {
        NSInteger code = [error code];
        
        if(code == ALAssetsLibraryAccessGloballyDeniedError || code == ALAssetsLibraryAccessUserDeniedError) {
            RenderJson(response, HttpStatusCodeForbidden, @{ @"message": [error localizedDescription] });
            return YES;
        }
    }
    
    return NO;
}

BOOL ServerError(HttpServerResponse *response, NSError *error) {
    if(error) {
        RenderString(response, HttpStatusCodeInternalServerError, [error localizedDescription]);
        return YES;
    }
    
    return NO;
}

BOOL EmptyParameter(HttpServerResponse *response, id parameter) {
    if(!parameter || parameter == [NSNull null]) {
        RenderJson(response, HttpStatusCodeBadRequest, @{ @"message": @"Required parameter missing" });
        return YES;
    }
    
    return NO;
}

BOOL ResourceNotFound(HttpServerResponse *response, id resource) {
    if(!resource) {
        RenderJson(response, HttpStatusCodeNotFound, @{ @"message": @"Resource not found" });
        return YES;
    }
    
    return NO;
}

@implementation ISServer {
    HttpServerRouterDelegate *_router;
    HttpServer *_server;
    
    ISMimeTypes *_mimeTypes;
    NSPredicate *_charset;
    
    ALAssetsLibrary *_assetsLibrary;
}

-(id) init {
    if(self = [super init]) {
        _router = [[HttpServerRouterDelegate alloc] init];
        _server = [[HttpServer alloc] init];
        
        _mimeTypes = [[ISMimeTypes alloc] initWithJsonFile:AssetsPath(@"mimetypes.json")];
        _charset = [[NSPredicate predicateWithFormat:@"(SELF BEGINSWITH \"text/\") AND NOT (SELF LIKE \"*charset=*\")"] retain];
        
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        
        _server.delegate = _router;
        
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
        [_router matchMethod:@"GET" path:@"/api/files/data" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getFileData:request response:response];
        }];
        
        [_router matchMethod:@"GET" path:@"/public/templates" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [self getTemplates:request response:response];
        }];
        
        [_router matchMethod:@"GET" path:@[@"/app/*", @"/app"]
                     request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [_router routeRequest:request response:response toMethod:@"GET" path:@"/public/index.html"];
        }];
        [_router matchMethod:@"GET" path:@"/" request:^(HttpServerRequest *request, HttpServerResponse *response) {
            [response writeHeaderStatus:HttpStatusCodeFound
                                headers:@{ @"Location": AbsoluteUrl(request, @"/app", nil) }];
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
        RenderString(response, HttpStatusCodeNotFound, [NSString stringWithFormat:@"%@ not found", path]);
        return;
    }
    
    NSString *mimeType = [_mimeTypes mimeTypeForExtensionWithFallback:[path pathExtension]];
    
    if([_charset evaluateWithObject:mimeType]) {
        mimeType = [mimeType stringByAppendingString:@"; charset=utf-8"];
    }
    
    [response.header setValue:mimeType forField:@"Content-Type"];
    
    RenderData(response, HttpStatusCodeOk, file);
}

-(void) getTemplates:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSError *error = nil;
    NSDictionary *directory = SerializeDirectory(AssetsPath(@"/public/templates"), NO, &error);
    
    if(ServerError(response, error)) {
        return;
    }
    
    NSData *json = [NSJSONSerialization dataWithJSONObject:directory options:0 error:&error];
    
    if(ServerError(response, error)) {
        return;
    }
    
    NSMutableData *body = [[@"window._templates = " dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [body appendData:json];
    
    [response.header setValue:@"application/javascript" forField:@"Content-Type"];
    RenderData(response, HttpStatusCodeOk, body);
    
    [body release];
}

-(void) getAlbums:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    [ISAlbum getAllUsingAssetsLibrary:_assetsLibrary block:^(NSArray *albums, NSError *error) {
        HTTP_ERROR(albums);
        
        albums = [albums mapObjectsUsingBlock:^(ISAlbum *album, NSUInteger i) {
            NSDictionary *query = @{ @"album": album.url };
            
            return [album toDictionary:@{
                @"files": AbsoluteUrl(request, @"/api/files", query),
                @"thumbnail": AbsoluteUrl(request, @"/api/albums/thumbnail", query)
            }];
        }];
        
        RenderJson(response, HttpStatusCodeOk, albums);
    }];
}

-(void) getFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    NSString *albumUrl = [request.header.url.query objectForKey:@"album"];
    
    if(EmptyParameter(response, albumUrl)) {
        return;
    }
    
    [ISFile getAllUsingAssetsLibrary:_assetsLibrary byAlbumUrl:albumUrl block:^(NSArray *files, NSError *error) {
        HTTP_ERROR(files);
     
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
     
        RenderJson(response, HttpStatusCodeOk, files);
    }];
}

-(void) getAlbumThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSString *albumUrl = [request.header.url.query objectForKey:@"album"];
    
    if(EmptyParameter(response, albumUrl)) {
        return;
    }
    
    [ISAlbum getUsingAssetsLibrary:_assetsLibrary byUrl:albumUrl block:^(ISAlbum *album, NSError *error) {
        HTTP_ERROR(album);
        
        NSInteger count = [album numberOfFiles];
        
        if(!count) {
            RenderData(response, HttpStatusCodeOk, nil);
            return;
        }
        
        [album getFileByIndex:(count - 1) block:^(ISFile *file, NSError *error) {
            HTTP_ERROR(file);
            
            [response.header setValue:ISImageGetRepresentationMimeType(ISImageRepresentationPNG) forField:@"Content-Type"];
            RenderData(response, HttpStatusCodeOk, [file getThumbnail:ISImageRepresentationPNG]);
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
    
    if(EmptyParameter(response, fileUrl)) {
        return;
    }
    
    [ISFile getUsingAssetsLibrary:_assetsLibrary byUrl:fileUrl block:^(ISFile *file, NSError *error) {
        HTTP_ERROR(file);
        
        if([request.header.url.query objectForKey:@"download"]) {
            [response.header setValue:[NSString stringWithFormat:@"attachment; filename=\"%@\"", file.name]
                        forField:@"Content-Disposition"];
        }
        
        [response writeHeaderStatus:HttpStatusCodeOk headers:@{
            @"Content-Type": [_mimeTypes mimeTypeForExtension:file.extension],
            @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)[file getDataLength]]
         }];
        
        StreamFileData(response, file, 0);
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
    [_assetsLibrary release];
    
    [super dealloc];
}

-(void) streamImage:(HttpServerRequest *)request response:(HttpServerResponse *)response
             block:(NSData* (^)(ISFile*, ISImageRepresentation))block {
    NSString *fileUrl = [request.header.url.query valueForKey:@"file"];
    
    if(EmptyParameter(response, fileUrl)) {
        return;
    }
    
    [ISFile getUsingAssetsLibrary:_assetsLibrary byUrl:fileUrl block:^(ISFile *file, NSError *error) {
        HTTP_ERROR(file);
        
        [response.header setValue:ISImageGetRepresentationMimeType(ISImageRepresentationPNG) forField:@"Content-Type"];
        RenderData(response, HttpStatusCodeOk, block(file, ISImageRepresentationPNG));
    }];
}
@end
