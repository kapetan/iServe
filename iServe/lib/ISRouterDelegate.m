//
//  HttpServerResolverDelegate.m
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISRouterDelegate.h"

#import "ISQueue.h"

@interface ISRequestQueue : ISQueue
@end

@implementation ISRequestQueue {
    ISRouterDelegate *_router;
}

-(id) initWithConcurrency:(NSInteger)concurrency router:(ISRouterDelegate*)router {
    if(self = [super initWithConcurrency:concurrency]) {
        self->_router = router;
    }
    
    return self;
}

-(void) runWithObject:(NSDictionary*)context {
    HttpServerRequest *request = [context objectForKey:@"request"];
    HttpServerResponse *response = [context objectForKey:@"response"];
    
    [_router routeRequest:request response:response];
}
@end

@implementation ISRequestResolver {
    NSArray *_routes;
    HttpServerRequest *_request;
    HttpServerResponse *_response;
    
    ISResolveContinueBlock _next;
    NSInteger _current;
}

-(id) initWithRoutes:(NSArray*)routes request:(HttpServerRequest*)request response:(HttpServerResponse*)response {
    if(self = [super init]) {
        __block ISRequestResolver *this = self;
        
        self->_routes = [routes retain];
        self->_request = [request retain];
        self->_response = [response retain];
        
        self->_current = 0;
        self->_next = [^{
            [this next];
        } copy];
    }
    
    return self;
}

-(void) next {
    if(_current == [_routes count]) {
        [_response writeHeaderStatus:HttpStatusCodeNotFound];
        [_response end];
        
        return;
    }
    
    ISRoute *route = [_routes objectAtIndex:_current++];
    
    if([route doesMatchMethod:_request.header.method andPath:_request.header.url.pathname]) {
        route.block(_request, _response, _next);
    } else {
        [self next];
    }
}

-(void) dealloc {
    [_routes release];
    [_request release];
    [_response release];
    
    [_next release];
    
    [super dealloc];
}
@end

@implementation ISRoute {
    NSPredicate *_match;
}

@synthesize method = _method;
@synthesize path = _path;
@synthesize block = _block;

-(id) init {
    return [self initWithMethod:@"GET" path:@"/" block:^(HttpServerRequest *request, HttpServerResponse *response) {
        [response end];
    }];
}

-(id) initWithMethod:(NSString*)method path:(NSString*)path continueableBlock:(ISResolveContinuableBlock)block {
    if(self = [super init]) {
        self->_method = [method retain];
        self->_path = [path retain];
        self->_block = [block copy];
        
        self->_match = [[NSPredicate predicateWithFormat:@"(SELF LIKE[c] %@) OR (SELF LIKE[c] %@)",
                         path, [path stringByAppendingString:@"/"]] retain];
    }
    
    return self;
}

-(id) initWithMethod:(NSString*)method path:(NSString*)path block:(ISResolveBlock)block {
    return [self initWithMethod:method path:path
              continueableBlock:^(HttpServerRequest *request, HttpServerResponse *response, ISResolveContinueBlock next) {
        block(request, response);
    }];
}

-(BOOL) doesMatchMethod:(NSString*)method andPath:(NSString*)path {
    return [_method isEqualToString:method] && [_match evaluateWithObject:path];
}

-(void) dealloc {
    [self->_method release];
    [self->_path release];
    [self->_match release];
    [self->_block release];
    
    [super dealloc];
}
@end

@implementation ISRouterDelegate {
    NSMutableDictionary *_routes;
    ISRequestQueue *_queue;
}

@synthesize error = _error;
@synthesize close = _close;

-(id) init {
    if(self = [super init]) {
        self->_routes = [[NSMutableDictionary alloc] init];
        self->_queue = [[ISRequestQueue alloc] initWithConcurrency:1 router:self];
    }
    
    return self;
}

-(void) matchMethod:(id)method path:(id)path request:(ISResolveBlock)request {
    [self matchMethod:method path:path
            continuableRequest:^(HttpServerRequest *req, HttpServerResponse *resp, ISResolveContinueBlock next) {
        request(req, resp);
    }];
}

-(void) matchMethod:(id)method path:(id)path continuableRequest:(ISResolveContinuableBlock)request {
    if(![method isKindOfClass:[NSArray class]]) {
        method = [NSArray arrayWithObject:method];
    }
    if(![path isKindOfClass:[NSArray class]]) {
        path = [NSArray arrayWithObject:path];
    }
    
    for (NSString *m in method) {
        for (NSString *p in path) {
            ISRoute *route = [[ISRoute alloc] initWithMethod:m path:p continueableBlock:request];
            [self matchRoute:[route autorelease]];
        }
    }
}

-(void) matchRoute:(ISRoute*)route {
    NSMutableArray *paths = [_routes objectForKey:route.method];
    
    if(!paths) {
        paths = [NSMutableArray array];
        [_routes setObject:paths forKey:route.method];
    }
    
    [paths addObject:route];
}

-(void) routeRequest:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSArray *routes = [_routes objectForKey:request.header.method];
    
    __block ISRequestResolver *resolver = [[ISRequestResolver alloc] initWithRoutes:routes request:request response:response];
    __block ISRouterDelegate *this = self;
    
    HttpServerResponseBlockDelegate *delegate = response.delegate;
    
    delegate.end = delegate.close = ^(HttpServerResponse *response) {
        response.caller = nil;
        
        [resolver release];
        [this->_queue completed];
    };
    
    if(request.resolver) {
        [request.resolver release];
    }
    
    request.resolver = resolver;
    
    [resolver next];
}

-(void) routeRequest:(HttpServerRequest *)request response:(HttpServerResponse *)response
            toMethod:(NSString *)method path:(NSString *)path {
    HttpUrl *url = [[HttpUrl alloc] initWithPathname:path query:request.header.url.query];
    
    request.header.method = method;
    request.header.url = [url autorelease];
    
    [self routeRequest:request response:response];
}

-(void) server:(HttpServer *)server request:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    NSDictionary *context = [[NSDictionary alloc] initWithObjectsAndKeys:request, @"request", response, @"response", nil];
    
    response.caller = [NSThread currentThread];
    
    [_queue pushObject:context];
    [context release];
}

-(void) server:(HttpServer *)server acceptedConnection:(TcpConnection *)connection {}

-(void) server:(HttpServer *)server client:(TcpConnection *)connection errorOccurred:(NSError *)error {}

-(void) server:(HttpServer *)server errorOccurred:(NSError *)error {
    if(self.error) self.error(self, error);
}

-(void) serverDidClose:(HttpServer *)server {
    if(self.close) self.close(self);
}
-(void) dealloc {
    [_routes release];
    [_queue release];
    
    [super dealloc];
}
@end
