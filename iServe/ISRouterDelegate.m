//
//  HttpServerResolverDelegate.m
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISRouterDelegate.h"

@interface Route : NSObject
@end

@implementation Route {
    NSString *_method;
    NSPredicate *_path;
    ISResolveBlock _block;
}

-(id) init {
    if(self = [super init]) {
        self->_method = @"GET";
        self->_path = [[NSPredicate predicateWithFormat:@"SELF LIKE \"*\""] retain];
        self->_block = Block_copy(^(HttpServerRequest *request, HttpServerResponse *response) {
            [response writeHeaderStatus:HttpStatusCodeNotFound];
            [response end];
        });
    }
    
    return self;
}

-(id) initWithMethod:(NSString*)method path:(NSString*)path block:(ISResolveBlock)block {
    if(self = [super init]) {
        self->_method = [method retain];
        self->_path = [[NSPredicate predicateWithFormat:@"(SELF LIKE[c] %@) OR (SELF LIKE[c] %@)",
                        path, [path stringByAppendingString:@"/"]] retain];
        self->_block = [block copy];
    }
    
    return self;
}

-(BOOL) doesMatchMethod:(NSString*)method andPath:(NSString*)path {
    return [_method isEqualToString:method] && [_path evaluateWithObject:path];
}

-(ISResolveBlock) getBlock {
    return _block;
}

-(void) dealloc {
    [self->_method release];
    [self->_path release];
    [self->_block release];
    
    [super dealloc];
}
@end

@implementation ISRouterDelegate {
    NSMutableDictionary *_routes;
    Route *_notFound;
}

-(id) init {
    if(self = [super init]) {
        self->_routes = [[NSMutableDictionary alloc] init];
        self->_notFound = [[Route alloc] init];
    }
    
    return self;
}

-(void) matchMethod:(id)method path:(id)path request:(ISResolveBlock)request {
    if(![method isKindOfClass:[NSArray class]]) {
        method = [NSArray arrayWithObject:method];
    }
    if(![path isKindOfClass:[NSArray class]]) {
        path = [NSArray arrayWithObject:path];
    }
    
    for (NSString *m in method) {
        for (NSString *p in path) {
            [self matchSingleMethod:m path:p request:request];
        }
    }
}

-(void) routeRequest:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSArray *paths = [_routes objectForKey:request.header.method];
    
    for (Route *route in paths) {
        if([route doesMatchMethod:request.header.method andPath:request.header.url.pathname]) {
            ISResolveBlock block = [route getBlock];
            block(request, response);
            
            return;
        }
    }
    
    [_notFound getBlock](request, response);
}

-(void) routeRequest:(HttpServerRequest *)request response:(HttpServerResponse *)response
            toMethod:(NSString *)method path:(NSString *)path {
    HttpUrl *url = [[HttpUrl alloc] initWithPathname:path query:request.header.url.query];
    
    request.header.method = method;
    request.header.url = [url autorelease];
    
    [self routeRequest:request response:response];
}

-(void) server:(HttpServer *)server request:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    [self routeRequest:request response:response];
}

-(void) server:(HttpServer *)server acceptedConnection:(TcpConnection *)connection {}

-(void) server:(HttpServer *)server client:(TcpConnection *)connection errorOccurred:(NSError *)error {}

-(void) server:(HttpServer *)server errorOccurred:(NSError *)error {}

-(void) serverDidClose:(HttpServer *)server {}

-(void) matchSingleMethod:(NSString *)method path:(NSString *)path request:(ISResolveBlock)request {
    NSMutableArray *paths = [_routes objectForKey:method];
    
    if(!paths) {
        paths = [NSMutableArray array];
        [_routes setObject:paths forKey:method];
    }
    
    Route *route = [[Route alloc] initWithMethod:method path:path block:request];
    [paths addObject:[route autorelease]];
}

-(void) dealloc {
    [_routes release];
    [_notFound release];
    
    [super dealloc];
}
@end
