//
//  File.h
//  iServe
//
//  Created by Mirza Kapetanovic on 9/29/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ISImage.h"

@class ISAlbum;
@class ISFile;

typedef void (^ISFileAllBlock) (NSArray*, NSError*);
typedef void (^ISFileGetBlock) (ISFile*, NSError*);

@interface ISFile : NSObject
+(void) getAllByAlbum:(ISAlbum*)album block:(ISFileAllBlock)block;
+(void) getAllByAssetsGroup:(ALAssetsGroup*)group block:(ISFileAllBlock)block;
+(void) getUsingAssetsLibrary:(ALAssetsLibrary*)library byUrl:(NSString*)url block:(ISFileGetBlock)block;
+(void) getAllUsingAssetsLibrary:(ALAssetsLibrary*)library byAlbumUrl:(NSString*)url block:(ISFileAllBlock)block;

+(void) getUsingAssetsGroup:(ALAssetsGroup *)group byIndex:(NSUInteger)index block:(ISFileGetBlock)block;
+(void) getUsingAlbum:(ISAlbum*)album byIndex:(NSUInteger)index block:(ISFileGetBlock)block;

+(NSString*) urlFromHashCode:(NSString*)hashCode;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *extension;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSDate *created;
@property (nonatomic, readonly) NSString *type;

@property (nonatomic, readonly) ALAsset *asset;

-(id) initWithAsset:(ALAsset*)asset;

-(NSData*) getThumbnailWithSize:(ISImageSize)size sizeOption:(ISImageScaleMode)mode
                 representation:(ISImageRepresentation)representation;
-(NSData*) getThumbnail:(ISImageRepresentation)representation;
-(NSData*) getImage:(ISImageRepresentation)representation;

-(NSUInteger) getDataLength;
-(NSData*) getData;
-(NSData*) getDataFromOffset:(NSUInteger)offset length:(NSUInteger)length;

-(NSString*) hashCode;

-(NSDictionary*) toDictionary;
-(NSDictionary*) toDictionary:(NSDictionary*)dictionary;
@end
