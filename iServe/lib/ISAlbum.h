//
//  Album.h
//  iServe
//
//  Created by Mirza Kapetanovic on 9/29/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ISImage.h"

@class ISFile;
@class ISAlbum;

typedef void (^ISAlbumAllBlock) (NSArray*, NSError*);
typedef void (^ISAlbumGetBlock) (ISAlbum*, NSError*);
typedef ISAlbumAllBlock ISAlbumAllFilesBlock;
typedef void (^ISAlbumFileBlock) (ISFile*, NSError*);

@interface ISAlbum : NSObject
+(void) getAllUsingAssetsLibrary:(ALAssetsLibrary*)library block:(ISAlbumAllBlock)block;
+(void) getUsingAssetsLibrary:(ALAssetsLibrary*)library byUrl:(NSString*)url block:(ISAlbumGetBlock)block;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *url;

@property (nonatomic, readonly) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, readonly) ALAssetsGroup *assetsGroup;

-(id) initWithAssetsLibrary:(ALAssetsLibrary*)library assetsGroup:(ALAssetsGroup*)group;

-(void) getAllFiles:(ISAlbumAllFilesBlock)block;
-(void) getFileByUrl:(NSString*)url block:(ISAlbumFileBlock)block;
-(void) getFileByIndex:(NSUInteger)index block:(ISAlbumFileBlock)block;

-(NSInteger) numberOfFiles;

-(NSDictionary*) toDictionary;
-(NSDictionary*) toDictionary:(NSDictionary*)dictionary;
@end
