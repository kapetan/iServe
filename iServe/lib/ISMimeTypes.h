//
//  MimeTypes.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISMimeTypes : NSObject
-(id) initWithJsonFile:(NSString*)path;

-(NSString*) mimeTypeForExtensionWithFallback:(NSString*)extension;
-(NSString*) mimeTypeForExtension:(NSString*)extension;

-(void) setMimeType:(NSString*)mimeType forExtension:(NSString*)extension;
@end
