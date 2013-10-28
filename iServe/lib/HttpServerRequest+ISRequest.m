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

static char ISRequestResolverKey;

@implementation HttpServerRequest (ISRequest)
-(ISRequestResolver*) resolver {
    return objc_getAssociatedObject(self, &ISRequestResolverKey);
}

-(void) setResolver:(ISRequestResolver *)resolver {
    objc_setAssociatedObject(self, &ISRequestResolverKey, resolver, OBJC_ASSOCIATION_ASSIGN);
}
@end
