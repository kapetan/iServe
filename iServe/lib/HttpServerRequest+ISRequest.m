//
//  HttpServerRequest+ISRequest.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <objc/runtime.h>

#import "HttpServerRequest+ISRequest.h"

#import "ISRouterDelegate.h"
#import "ISCookie.h"

static char ISRequestResolverKey;
static char ISRequestCookieKey;

@implementation HttpServerRequest (ISRequest)
-(ISRequestResolver*) resolver {
    return objc_getAssociatedObject(self, &ISRequestResolverKey);
}

-(void) setResolver:(ISRequestResolver *)resolver {
    objc_setAssociatedObject(self, &ISRequestResolverKey, resolver, OBJC_ASSOCIATION_ASSIGN);
}

-(NSDictionary*) cookie {
    NSDictionary *cookie = objc_getAssociatedObject(self, &ISRequestCookieKey);
    
    if(!cookie) {
        NSString *header = [self.header valueForKey:@"Cookie"];
        
        if(header) {
            cookie = [ISCookie cookieNameValuePairsWithString:header error:NULL];
        }
        if(!cookie) {
            cookie = [NSDictionary dictionary];
        }
        
        objc_setAssociatedObject(self, &ISRequestCookieKey, cookie, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return cookie;
}
@end
