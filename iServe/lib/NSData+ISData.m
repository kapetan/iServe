//
//  NSData+ISDigest.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/28/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "NSData+ISData.h"

@implementation ISBitMap {
    uint8_t *_bytes;
    NSUInteger _length;
    
    BOOL _owns;
}

-(id) initWithData:(NSData*)data {
    return [self initWithBytes:(uint8_t*) data.bytes length:data.length copy:YES];
}

-(id) initWithBytes:(uint8_t*)buffer length:(NSUInteger)length copy:(BOOL)copy {
    if(self = [super init]) {
        if(copy) {
            uint8_t *dest = (uint8_t*) malloc(length);
            memcpy(dest, buffer, length);
            
            _bytes = dest;
            _length = length;
        } else {
            _bytes = buffer;
            _length = length;
        }
        
        _owns = copy;
    }
    
    return self;
}

-(id) initWithLength:(NSUInteger)length {
    if(self = [super init]) {
        self->_bytes = (uint8_t*) malloc(length);
        self->_length = length;
    }
    
    return self;
}

-(const uint8_t*) bytes {
    return _bytes;
}

-(NSUInteger) byteLengthFromOffset:(NSUInteger)offset {
    double bits = (_length * 8.0) - offset;
    return ceill(bits / 8.0);
}


-(void) setBytes:(const uint8_t*)bytes fromOffset:(NSUInteger)offset lenght:(NSUInteger)lenght {
    NSUInteger availableLength = [self byteLengthFromOffset:offset];
    
    for(NSInteger i = 0; i < MIN(availableLength, lenght); i++) {
        [self setByte:bytes[i] atOffset:offset + (i * 8)];
    }
}

-(void) bytes:(uint8_t*)bytes atOffset:(NSUInteger)offset lenght:(NSUInteger)lenght {
    NSUInteger availableLength = [self byteLengthFromOffset:offset];
    
    for(NSInteger i = 0; i < MIN(availableLength, lenght); i++) {
        bytes[i] = [self byteAtOffset:offset + (i * 8)];
    }
}

-(uint8_t) byteAtOffset:(NSUInteger)offset {
    NSUInteger byteIndex = offset / 8;
    NSUInteger byteOffset = offset % 8;
    
    uint8_t heighBits = _bytes[byteIndex] << byteOffset;
    uint8_t lowBits = 0;
    
    if(++byteIndex < _length) {
        lowBits = _bytes[byteIndex] >> (8 - byteOffset);
    }
    
    return heighBits | lowBits;
}

-(void) setByte:(uint8_t)byte atOffset:(NSUInteger)offset {
    NSUInteger byteIndex = offset / 8;
    NSUInteger byteOffset = offset % 8;
    
    uint8_t heighBits = byte >> byteOffset;
    uint8_t lowBits = byte << (8 - byteOffset);
    
    _bytes[byteIndex] = (_bytes[byteIndex] & ~(0xFF >> byteOffset)) | heighBits;
    
    if(++byteIndex < _length) {
        _bytes[byteIndex] = (_bytes[byteIndex] & ~(0xFF << (8 - byteOffset))) | lowBits;
    }
}

-(void) shiftByteLeft:(NSUInteger)i offset:(NSUInteger)offset {
    uint8_t b = [self byteAtOffset:offset];
    [self setByte:(b << i) atOffset:offset];
}

-(void) shiftByteRight:(NSUInteger)i offset:(NSUInteger)offset {
    uint8_t b = [self byteAtOffset:offset];
    [self setByte:(b >> i) atOffset:offset];
}

-(void) shiftLeft:(NSUInteger)i fromOffset:(NSUInteger)offset {
    uint8_t carryMask = ~(0xFF >> i);
    uint8_t carry = 0;
    
    NSUInteger length = [self byteLengthFromOffset:offset];
    
    for(NSInteger j = length - 1; j >= 0; j--) {
        NSUInteger currentOffset = offset + (j * 8);
        uint8_t b = [self byteAtOffset:currentOffset];
        uint8_t carryNew = b & carryMask;
        
        b = (b << i) | (carry >> (8 - i));
        
        [self setByte:b atOffset:currentOffset];
        carry = carryNew;
    }
}

-(void) shiftRight:(NSUInteger)i fromOffset:(NSUInteger)offset {
    uint8_t carryMask = ~(0xFF << i);
    uint8_t carry = 0;
    
    NSUInteger length = [self byteLengthFromOffset:offset];

    for(NSInteger j = 0; j < length; j++) {
        NSUInteger currentOffset = offset + (j * 8);
        uint8_t b = [self byteAtOffset:currentOffset];
        uint8_t carryNew = b & carryMask;
        
        b = (b >> i) | (carry << (8 - i));
        
        [self setByte:b atOffset:currentOffset];
        carry = carryNew;
    }
}

-(NSData*) data {
    return [NSData dataWithBytes:_bytes length:_length];
}

-(NSString*) description {
    NSMutableString *result = [NSMutableString stringWithCapacity:(_length * 8) + _length];
    
    [result appendString:@"|"];
    
    for(NSUInteger i = 0; i < _length; i++) {
        uint8_t byte = _bytes[i];
        
        for(int j = 0; j < 8; j++) {
            uint8_t b = (byte << j) & 0x80;
            [result appendFormat:@"%i", !!b];
        }
        
        [result appendString:@"|"];
    }
    
    return result;
}

-(void) dealloc {
    if(_owns) {
        free((void*) _bytes);
    }
    
    [super dealloc];
}
@end

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

-(NSData*) compressAscii {
    ISBitMap *bits = [[ISBitMap alloc] initWithData:self];
    NSUInteger length = ceill(self.length * 7.0 / 8.0);
    
    for(NSInteger i = 0; i < length * 8; i += 7) {
        [bits shiftLeft:1 fromOffset:i];
    }
    
    NSData *result = [NSData dataWithBytes:bits.bytes length:length];
    [bits release];
    
    return result;
}

-(NSData*) decompressAscii {
    NSUInteger length = floor(self.length * 8.0 / 7.0);
    ISBitMap *bits = [[ISBitMap alloc] initWithLength:length];
    
    [bits setBytes:self.bytes fromOffset:0 lenght:self.length];
    
    for(NSInteger i = 0; i < length * 8; i += 8) {
        [bits shiftRight:1 fromOffset:i];
    }
    
    NSData *result = [bits data];
    [bits release];
    
    return result;
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
