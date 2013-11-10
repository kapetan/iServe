//
//  HttpServerResponse+ISResponse.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerResponse.h"

#import "ISAction.h"
#import "ISCookie.h"

@interface HttpServerResponse (ISResponse)
@property (nonatomic, weak) NSThread *caller;

-(void) executeOnCallerThread:(ISActionBlock)block;

-(void) sendData:(NSData*)body statusCode:(HttpStatusCode)status;
-(void) sendString:(NSString*)body statusCode:(HttpStatusCode)status;
-(void) sendJson:(id)body statusCode:(HttpStatusCode)status;

-(void) sendData:(NSData *)body;
-(void) sendString:(NSString *)body;
-(void) sendJson:(id)body;

-(void) sendServerError:(NSString*)message;
-(void) sendBadRequest:(NSString*)message;
-(void) sendForbidden:(NSString*)message;
-(void) sendNotFound:(NSString*)message;

-(void) sendError:(NSError*)error;

-(void) redirectToLocation:(NSString*)location withStatusCode:(HttpStatusCode)status;
-(void) redirectToLocation:(NSString *)location;

-(void) setExpires:(NSDate*)date;
-(void) setCacheControl:(NSString*)control maxAge:(NSUInteger)age;
-(void) cache:(NSUInteger)seconds;

-(void) setCookie:(ISCookie*)cookie;
-(void) setCookieWithName:(NSString*)name value:(NSString*)value;
-(void) setCookieWithName:(NSString*)name value:(NSString*)value expires:(NSDate*)date;
-(void) removeCookie:(NSString*)name;
@end
