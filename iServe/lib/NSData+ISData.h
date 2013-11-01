//
//  NSData+ISDigest.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISBitMap : NSObject
@property (nonatomic, readonly) const uint8_t* bytes;

-(id) initWithData:(NSData*)data;
-(id) initWithBytes:(uint8_t*)buffer length:(NSUInteger)length copy:(BOOL)copy;
-(id) initWithLength:(NSUInteger)length;

-(NSUInteger) byteLengthFromOffset:(NSUInteger)offset;

-(void) setBytes:(const uint8_t*)bytes fromOffset:(NSUInteger)offset lenght:(NSUInteger)lenght;
-(void) bytes:(uint8_t*)bytes atOffset:(NSUInteger)offset lenght:(NSUInteger)lenght;

-(uint8_t) byteAtOffset:(NSUInteger)offset;
-(void) setByte:(uint8_t)byte atOffset:(NSUInteger)offset;

-(void) shiftByteLeft:(NSUInteger)i offset:(NSUInteger)offset;
-(void) shiftByteRight:(NSUInteger)i offset:(NSUInteger)offset;
-(void) shiftLeft:(NSUInteger)i fromOffset:(NSUInteger)offset;
-(void) shiftRight:(NSUInteger)i fromOffset:(NSUInteger)offset;

-(NSData*) data;
@end

@interface NSData (ISData)
+(NSData*) dataWithHexString:(NSString*)string;

-(NSData*) compressAscii;
-(NSData*) decompressAscii;
-(NSString*) hexEncode;
@end
