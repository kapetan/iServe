//
//  NSData+ISDigest.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "NSData+ISData.h"

@implementation NSData (ISData)
+(NSData*) dataWithHexString:(NSString *)string {
    NSUInteger length = string.length / 2;
    NSMutableData *result = [NSMutableData dataWithCapacity:length];
    const char *chars = [string cStringUsingEncoding:NSASCIIStringEncoding];
    
    char buffer[3] = { '\0', '\0', '\0' };
    NSInteger i = 0;
    
    while(i < length) {
        buffer[0] = chars[i++];
        buffer[1] = chars[i++];
        
        NSUInteger byte = strtoul(buffer, NULL, 16);
        [result appendBytes:&byte length:1];
    }
    
    return result;
}

-(NSData*) sha1 {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(self.bytes, self.length, digest);
    
    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

-(NSString*) hexEncode {
    uint8_t *bytes = (uint8_t*) self.bytes;
    
    NSMutableString *hex = [NSMutableString stringWithCapacity:self.length * 2];
    
    for(int i = 0; i < self.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    
    return hex;
}
@end
