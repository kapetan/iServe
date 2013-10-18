//
//  HttpServerResolverDelegate.h
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

typedef void (^ISResolveBlock)(HttpServerRequest *, HttpServerResponse *);

@interface ISRouterDelegate : NSObject <HttpServerDelegate>
@property (nonatomic, copy) void (^error)(ISRouterDelegate*, NSError*);
@property (nonatomic, copy) void (^close)(ISRouterDelegate*);

-(void) matchMethod:(id)method path:(id)path request:(ISResolveBlock)request;

-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response
            toMethod:(NSString*)method path:(NSString*)path;
@end
