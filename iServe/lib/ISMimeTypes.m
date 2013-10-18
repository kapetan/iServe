//
//  MimeTypes.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISMimeTypes.h"

NSString *DEFAULT_MIME_TYPE = @"application/octet-stream";

NSString *NormalizeExtension(NSString *extension) {
    if([extension hasPrefix:@"."]) {
        extension = [extension stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    return [extension lowercaseString];
}

@implementation ISMimeTypes {
    NSMutableDictionary *_types;
}

-(id) init {
    if(self = [super init]) {
        _types = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(id) initWithJsonFile:(NSString*)path {
    if(self = [self init]) {
        NSError *error = nil;
        NSData *json = [NSData dataWithContentsOfFile:path];
        
        if(!json) {
            [self release];
            return nil;
        }
        
        NSArray *types = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
        
        if(error) {
            [self release];
            return nil;
        }
        
        for (NSDictionary *obj in types) {
            NSString *extension = [[obj allKeys] objectAtIndex:0];
            [self setMimeType:[obj objectForKey:extension] forExtension:extension];
        }
    }
    
    return self;
}

-(NSString*) mimeTypeForExtensionWithFallback:(NSString*)extension {
    NSString *type = [self mimeTypeForExtension:extension];

    if(!type) {
        return DEFAULT_MIME_TYPE;
    }
    
    return type;
}

-(NSString*) mimeTypeForExtension:(NSString*)extension {
    return [_types objectForKey:NormalizeExtension(extension)];
}

-(void) setMimeType:(NSString*)mimeType forExtension:(NSString*)extension {
    [_types setObject:mimeType forKey:NormalizeExtension(extension)];
}

-(NSString*) description {
    return [_types description];
}

-(void) dealloc {
    [_types release];
    
    [super dealloc];
}
@end
