//
//  NSImage.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/5/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISImage.h"

NSString *ISImageGetRepresentationMimeType(ISImageRepresentation representation) {
    switch (representation) {
        case ISImageRepresentationJPEG:
            return @"image/jpeg";
        case ISImageRepresentationPNG:
            return @"image/png";
        default:
            return @"application/octet-stream";
    }
}

NSData *ISImageGetData(CGImageRef image, ISImageRepresentation representation) {
    UIImage *uiImage = [UIImage imageWithCGImage:image];
    
    if(representation == ISImageRepresentationJPEG) {
        return UIImageJPEGRepresentation(uiImage, 1.0f);
    } else {
        return UIImagePNGRepresentation(uiImage);
    }
}

ISImageSize ISImageScaleSize(ISImageSize image, ISImageSize target, ISImageScaleMode mode) {
    if(mode == ISImageScaleModeFill) {
        return target;
    }
    
    double widthRatio = (double) target.width / (double) image.width;
    double heightRatio = (double) target.height / (double) image.height;
    
    double ratio = 1.0;
    
    if(mode == ISImageScaleModeContain) {
        ratio = MIN(widthRatio, heightRatio);
    }
    if(mode == ISImageScaleModeCover) {
        ratio = MAX(widthRatio, heightRatio);
    }
    
    if(ratio >= 1.0) {
        return image;
    }
    
    ISImageSize result = { (size_t) (ratio * image.width), (size_t) (ratio * image.height) };
    return result;
}

NSData *ISImageScale(CGImageRef image, ISImageSize target, ISImageScaleMode mode, ISImageRepresentation representation) {
    ISImageSize imageSize = { CGImageGetWidth(image), CGImageGetHeight(image) };
    ISImageSize thumbSize = ISImageScaleSize(imageSize, target, mode);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL, thumbSize.width, thumbSize.height,
                                                8, 4 * thumbSize.width, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, thumbSize.width, thumbSize.height), image);
    CGImageRef thumb = CGBitmapContextCreateImage(bitmap);
    
    NSData *data = ISImageGetData(thumb, representation);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(bitmap);
    CGImageRelease(thumb);
    
    return data;
}