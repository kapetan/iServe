//
//  NSImage.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/5/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    size_t width;
    size_t height;
} ISImageSize;

typedef enum {
    ISImageScaleModeCover = 0,
    ISImageScaleModeContain,
    ISImageScaleModeFill
} ISImageScaleMode;

typedef enum {
    ISImageRepresentationJPEG = 0,
    ISImageRepresentationPNG
} ISImageRepresentation;

NSString *ISImageGetRepresentationMimeType(ISImageRepresentation representation);
NSData *ISImageGetData(CGImageRef image, ISImageRepresentation representation);

ISImageSize ISImageScaleSize(ISImageSize image, ISImageSize target, ISImageScaleMode mode);
NSData *ISImageScale(CGImageRef image, ISImageSize target, ISImageScaleMode mode, ISImageRepresentation representation);
