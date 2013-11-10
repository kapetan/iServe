//
//  HttpServerRequest+ISRequest.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerRequest.h"

@class ISRequestResolver;

@interface HttpServerRequest (ISRequest)
@property (nonatomic, assign) ISRequestResolver *resolver;
@property (nonatomic, readonly) NSDictionary *cookie;
@end
