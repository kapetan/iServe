//
//  HttpServerResolverDelegate.h
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

#import "HttpServerRequest+ISRequest.h"
#import "HttpServerResponse+ISResponse.h"

typedef void(^ISResolveContinueBlock)(void);
typedef void(^ISResolveContinuableBlock)(HttpServerRequest*, HttpServerResponse*, ISResolveContinueBlock next);

typedef void(^ISResolveBlock)(HttpServerRequest*, HttpServerResponse*);

@interface ISRequestResolver : NSObject
-(id) initWithRoutes:(NSArray*)routes request:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) next;
@end

@interface ISRoute : NSObject
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) ISResolveContinuableBlock block;

-(id) initWithMethod:(NSString*)method path:(NSString*)path continueableBlock:(ISResolveContinuableBlock)block;
-(id) initWithMethod:(NSString*)method path:(NSString*)path block:(ISResolveBlock)block;

-(BOOL) doesMatchMethod:(NSString*)method andPath:(NSString*)path;
@end

@interface ISRouterDelegate : NSObject <HttpServerDelegate>
@property (nonatomic, copy) void (^error)(ISRouterDelegate*, NSError*);
@property (nonatomic, copy) void (^close)(ISRouterDelegate*);

-(void) matchMethod:(id)method path:(id)path request:(ISResolveBlock)request;
-(void) matchMethod:(id)method path:(id)path continuableRequest:(ISResolveContinuableBlock)request;
-(void) matchRoute:(ISRoute*)route;

-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) routeRequest:(HttpServerRequest*)request response:(HttpServerResponse*)response
            toMethod:(NSString*)method path:(NSString*)path;
@end
