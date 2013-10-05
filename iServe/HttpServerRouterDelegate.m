//
//  HttpServerResolverDelegate.m
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerRouterDelegate.h"

@interface Route : NSObject
@end

@implementation Route {
    NSString *_method;
    NSPredicate *_path;
    HttpServerResolveBlock _block;
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

-(id) initWithMethod:(NSString*)method path:(NSString*)path block:(HttpServerResolveBlock)block {
    if(self = [super init]) {
        self->_method = [method retain];
        self->_path = [[NSPredicate predicateWithFormat:@"SELF LIKE %@", path] retain];
        self->_block = [block copy];
    }
    
    return self;
}

-(BOOL) doesMatchMethod:(NSString*)method andPath:(NSString*)path {
    return [_method isEqualToString:method] && [_path evaluateWithObject:path];
}

-(HttpServerResolveBlock) getBlock {
    return _block;
}

-(void) dealloc {
    [self->_method release];
    [self->_path release];
    [self->_block release];
    
    [super dealloc];
}
@end

@implementation HttpServerRouterDelegate {
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

-(void) route:(NSString *)method path:(NSString *)path request:(HttpServerResolveBlock)request {
    NSMutableArray *paths = [_routes objectForKey:method];
    
    if(!paths) {
        paths = [NSMutableArray array];
        [_routes setObject:paths forKey:method];
    }
    
    Route *route = [[Route alloc] initWithMethod:method path:path block:request];
    [paths addObject:[route autorelease]];
}

-(void) resolveRequest:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSArray *paths = [_routes objectForKey:request.header.method];
    
    for (Route *route in paths) {
        if([route doesMatchMethod:request.header.method andPath:request.header.url.pathname]) {
            HttpServerResolveBlock block = [route getBlock];
            block(request, response);
            
            return;
        }
    }
    
    [_notFound getBlock](request, response);
}

-(void) server:(HttpServer *)server request:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    [self resolveRequest:request response:response];
}

-(void) server:(HttpServer *)server acceptedConnection:(TcpConnection *)connection {}

-(void) server:(HttpServer *)server client:(TcpConnection *)connection errorOccurred:(NSError *)error {}

-(void) server:(HttpServer *)server errorOccurred:(NSError *)error {}

-(void) serverDidClose:(HttpServer *)server {}

-(void) dealloc {
    [_routes release];
    [_notFound release];
    
    [super dealloc];
}
@end
