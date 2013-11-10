//
//  ISCookie.m
//  iServe
//
//  Created by Mirza Kapetanovic on 09/11/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISCookie.h"

#import "HttpHeader.h"

#define PARSE_ERROR(obj, error) do { \
        if(error != NULL) *error = ISCookieError(@"Invalid cookie format"); \
        [obj release]; \
        return nil; \
    } while(0)

#define PAIR(key, value) [NSString stringWithFormat:@"%@=%@", key, value]

NSString *ISCookieErrorDomain = @"ISCookieError";

NSError *ISCookieError(NSString *message) {
    return [NSError errorWithDomain:ISCookieErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: message }];
}

NSString *NSStringTrim(NSString* str) {
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@implementation ISCookie {
    NSDateFormatter *_formatter;
}

@synthesize name = _name;
@synthesize value = _value;
@synthesize expires = _expires;
@synthesize maxAge = _maxAge;
@synthesize domain = _domain;
@synthesize path = _path;
@synthesize secure = _secure;
@synthesize httpOnly = _httpOnly;

+(NSArray*) cookieArrayWithString:(NSString*)string error:(NSError**)error {
    NSArray *cookies = [string componentsSeparatedByString:@";"];
    
    NSError *err = nil;
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSString* cookie in cookies) {
        ISCookie *parsed = [[ISCookie alloc] initWithString:cookie error:&err];
        
        if(err) {
            if(error != NULL) *error = err;
            return nil;
        }
        
        [result addObject:parsed];
        [parsed release];
    }
    
    return result;
}

+(NSDictionary*) cookieNameValuePairsWithString:(NSString*)string error:(NSError**)error {
    NSError *err = nil;
    NSArray *cookies = [ISCookie cookieArrayWithString:string error:&err];
    
    if(err) {
        if(error != NULL) *error = err;
        return nil;
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:cookies.count];
    
    for (ISCookie *cookie in cookies) {
        [result setObject:cookie.value forKey:cookie.name];
    }
    
    return result;
}

-(id) init {
    if(self = [super init]) {
        self->_name = nil;
        self->_value = nil;
        self->_expires = nil;
        self->_maxAge = 0;
        self->_domain = nil;
        self->_path = nil;
        self->_secure = NO;
        self->_httpOnly = NO;
        
        self->_formatter = NSDateFormatterCreateRFC1123();
    }
    
    return self;
}

-(id) initWithString:(NSString*)string error:(NSError**)error {
    if(self = [self init]) {
        NSArray *pairs = [string componentsSeparatedByString:@";"];
        
        if(!pairs.count) PARSE_ERROR(self, error);
        
        for(int i = 0; i < pairs.count; i++) {
            NSArray *pair = [[pairs objectAtIndex:i] componentsSeparatedByString:@"="];
            
            NSString *key = NSStringTrim([pair objectAtIndex:0]);
            NSString *value = pair.count == 2 ? NSStringTrim([pair objectAtIndex:1]) : nil;
            
            if(!i) {
                if(!value) PARSE_ERROR(self, error);
                
                self->_name = [key retain];
                self->_value = [UrlDecode(value) retain];
            } else if([key isEqualToString:@"HttpOnly"]) {
                self->_httpOnly = YES;
            } else if([key isEqualToString:@"Secure"]) {
                self->_secure = YES;
            } else if([key isEqualToString:@"Expires"]) {
                if(!value) PARSE_ERROR(self, error);
                
                NSDate *date = [_formatter dateFromString:value];
                
                if(!date) PARSE_ERROR(self, error);
                
                self->_expires = [date retain];
            } else if([key isEqualToString:@"Max-Age"]) {
                if(!value) PARSE_ERROR(self, error);
                
                self->_maxAge = [value intValue];
            } else if([key isEqualToString:@"Domain"]) {
                if(!value) PARSE_ERROR(self, error);
                
                self->_domain = [value retain];
            } else if([key isEqualToString:@"Path"]) {
                if(!value) PARSE_ERROR(self, error);
                
                self->_path = [value retain];
            }
        }
    }
    
    return self;
}

-(NSString*) toString {
    NSMutableArray *cookie = [NSMutableArray array];
    
    [cookie addObject:PAIR(_name, UrlEncode(_value))];
    
    if(_expires) [cookie addObject:PAIR(@"Expires", [_formatter stringFromDate:_expires])];
    if(_domain) [cookie addObject:PAIR(@"Domain", _domain)];
    if(_path) [cookie addObject:PAIR(@"Path", _path)];
    if(_secure) [cookie addObject:@"Secure"];
    if(_httpOnly) [cookie addObject:@"HttpOnly"];
    
    if(_maxAge) {
        NSString *age = [NSString stringWithFormat:@"%d", _maxAge];
        [cookie addObject:PAIR(@"Max-Age", age)];
    }
    
    
    return [cookie componentsJoinedByString:@"; "];
}

-(void) dealloc {
    [_name release];
    [_value release];
    [_expires release];
    [_domain release];
    [_path release];
    
    [_formatter release];
    
    [super dealloc];
}
@end
