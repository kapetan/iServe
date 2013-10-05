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
-(void) route:(NSString *)method path:(NSString*)path request:(HttpServerResolveBlock)request;
-(void) resolveRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response;
@end
