//
//  HttpServerResponse+ISResponse.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>

#import "HttpServerResponse+ISResponse.h"

#import "ISAction.h"

static char ISResponseCallerKey;

@implementation HttpServerResponse (ISResponse)
-(NSThread*) caller {
    return objc_getAssociatedObject(self, &ISResponseCallerKey);
}

-(void) setCaller:(NSThread *)caller {
    objc_setAssociatedObject(self, &ISResponseCallerKey, caller, OBJC_ASSOCIATION_ASSIGN);
}

-(void) sendData:(NSData *)body statusCode:(HttpStatusCode)status {
    [ISAction executeBlockOnThread:self.caller waitUntilDone:NO block:^{
        NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
        
        [self writeHeaderStatus:status headers:@{ @"Content-Length": length }];
        [self write:body];
        [self end];
    }];
}

-(void) sendString:(NSString *)body statusCode:(HttpStatusCode)status {
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    if(![self.header fieldValue:@"Content-Type"]) {
        [self.header setValue:@"text/plain; charset=utf-8" forField:@"Content-Type"];
    }
    
    [self sendData:data statusCode:status];
}

-(void) sendJson:(id)body statusCode:(HttpStatusCode)status {
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    
    if(error) {
        [self sendServerError:[error localizedDescription]];
        return;
    }
    
    [self.header setValue:@"application/json" forField:@"Content-Type"];
    [self sendData:json statusCode:status];
}

-(void) sendData:(NSData *)body {
    [self sendData:body statusCode:HttpStatusCodeOk];
}

-(void) sendString:(NSString *)body {
    [self sendString:body statusCode:HttpStatusCodeOk];
}

-(void) sendJson:(id)body {
    [self sendJson:body statusCode:HttpStatusCodeOk];
}

-(void) sendServerError:(NSString *)message {
    [self sendJson:@{ @"message": message } statusCode:HttpStatusCodeInternalServerError];
}

-(void) sendBadRequest:(NSString *)message {
    [self sendJson:@{ @"message": message } statusCode:HttpStatusCodeBadRequest];
}

-(void) sendForbidden:(NSString *)message {
    [self sendJson:@{ @"message": message } statusCode:HttpStatusCodeForbidden];
}

-(void) sendNotFound:(NSString *)message {
    [self sendJson:@{ @"message": message } statusCode:HttpStatusCodeNotFound];
}

-(void) sendError:(NSError *)error {
    NSString *message = [error localizedDescription];
    
    if(error && [[error domain] isEqualToString:ALAssetsLibraryErrorDomain]) {
        NSInteger code = [error code];
        
        if(code == ALAssetsLibraryAccessGloballyDeniedError || code == ALAssetsLibraryAccessUserDeniedError) {
            [self sendForbidden:message];
            return;
        }
    }
    
    [self sendServerError:message];
}
@end
