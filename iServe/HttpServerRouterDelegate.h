//
//  HttpServerResolverDelegate.h
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

typedef void (^HttpServerResolveBlock)(HttpServerRequest *, HttpServerResponse *);

@interface HttpServerRouterDelegate : NSObject <HttpServerDelegate>
-(void) matchMethod:(id)method path:(id)path request:(HttpServerResolveBlock)request;

-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response
            toMethod:(NSString*)method path:(NSString*)path;
@end
