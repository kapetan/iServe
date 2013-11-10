//
//  ISCookie.h
//  iServe
//
//  Created by Mirza Kapetanovic on 09/11/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *ISCookieErrorDomain;

@interface ISCookie : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, retain) NSDate *expires;
@property (nonatomic) NSInteger maxAge;
@property (nonatomic, retain) NSString *domain;
@property (nonatomic, retain) NSString *path;
@property (nonatomic) BOOL secure;
@property (nonatomic) BOOL httpOnly;

+(NSArray*) cookieArrayWithString:(NSString*)string error:(NSError**)error;
+(NSDictionary*) cookieNameValuePairsWithString:(NSString*)string error:(NSError**)error;

-(id) initWithString:(NSString*)string error:(NSError**)error;

-(NSString*) toString;
@end
