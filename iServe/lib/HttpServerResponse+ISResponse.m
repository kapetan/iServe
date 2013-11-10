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

//#import "HttpHeader.h"

static char ISResponseCallerKey;

@implementation HttpServerResponse (ISResponse)
-(NSThread*) caller {
    return objc_getAssociatedObject(self, &ISResponseCallerKey);
}

-(void) setCaller:(NSThread *)caller {
    objc_setAssociatedObject(self, &ISResponseCallerKey, caller, OBJC_ASSOCIATION_ASSIGN);
}

-(void) executeOnCallerThread:(ISActionBlock)block {
    [ISAction executeBlockOnThread:self.caller waitUntilDone:NO block:block];
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

-(void) redirectToLocation:(NSString*)location withStatusCode:(HttpStatusCode)status {
    [self.header setValue:location forField:@"Location"];
    [self writeHeaderStatus:status];
    [self end];
}

-(void) redirectToLocation:(NSString *)location {
    [self redirectToLocation:location withStatusCode:HttpStatusCodeFound];
}

-(void) setExpires:(NSDate*)date {
    NSDateFormatter *formatter = NSDateFormatterCreateRFC1123();
    
    [self.header setValue:[formatter stringFromDate:date] forField:@"Expires"];
    [formatter release];
}

-(void) setCacheControl:(NSString*)control maxAge:(NSUInteger)age {
    NSString *value = [NSString stringWithFormat:@"%@; max-age=%lu", control, (unsigned long)age];
    
    [self.header setValue:value forField:@"Cache-Control"];
}

-(void) cache:(NSUInteger)seconds {
    [self setExpires:[NSDate dateWithTimeIntervalSinceNow:seconds]];
    [self setCacheControl:@"public" maxAge:seconds];
}

-(void) setCookie:(ISCookie*)cookie {
    NSString *setCookieHeader = [self.header fieldValue:@"Set-Cookie"];
    
    if(setCookieHeader) {
        setCookieHeader = [NSString stringWithFormat:@"%@,%@", setCookieHeader, [cookie toString]];
    } else {
        setCookieHeader = [cookie toString];
    }
    
    [self.header setValue:setCookieHeader forField:@"Set-Cookie"];
}

-(void) setCookieWithName:(NSString*)name value:(NSString*)value {
    [self setCookieWithName:name value:value expires:nil];
}

-(void) setCookieWithName:(NSString*)name value:(NSString*)value expires:(NSDate*)date {
    ISCookie *cookie = [[ISCookie alloc] init];
    
    cookie.name = name;
    cookie.value = value;
    cookie.expires = date;
    cookie.path = @"/";
    
    [self setCookie:cookie];
    [cookie release];
}

-(void) removeCookie:(NSString*)name {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [self setCookieWithName:name value:@"0" expires:date];
}
@end
