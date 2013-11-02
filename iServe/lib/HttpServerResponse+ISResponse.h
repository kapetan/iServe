//
//  HttpServerResponse+ISResponse.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerResponse.h"

#import "ISAction.h"

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

-(void) setExpires:(NSDate*)date;
-(void) setCacheControl:(NSString*)control maxAge:(NSUInteger)age;
-(void) cache:(NSUInteger)seconds;
@end
