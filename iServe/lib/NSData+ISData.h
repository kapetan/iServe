//
//  NSData+ISDigest.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ISData)
+(NSData*) dataWithHexString:(NSString*)string;

-(NSData*) sha1;
-(NSString*) hexEncode;
@end
