//
//  File.m
//  iServe
//
//  Created by Mirza Kapetanovic on 9/29/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISFile.h"
#import "ISAlbum.h"

#import "ISAction.h"

#import "NSDictionary+ISCollection.h"

ISImageSize DEFAULT_THUMBNAIL_SIZE = { 300, 200 };
ISImageScaleMode DEFAULT_THUMBNAIL_MODE = ISImageScaleModeCover;

@implementation ISFile
+(void) getAllUsingAssetsLibrary:(ALAssetsLibrary*)library byAlbumUrl:(NSString*)url block:(ISFileAllBlock)block {
    [ISAlbum getUsingAssetsLibrary:library byUrl:url block:^(ISAlbum *album, NSError *error) {
        if(error) {
            block(nil, error);
            return;
        }
        if(!album) {
            block(nil, nil);
            return;
        }
        
        [ISFile getAllByAlbum:album block:block];
    }];
}

+(void) getAllByAlbum:(ISAlbum*)album block:(ISFileAllBlock)block {
    [ISFile getAllByAssetsGroup:album.assetsGroup block:block];
}

+(void) getAllByAssetsGroup:(ALAssetsGroup *)group block:(ISFileAllBlock)block {
    NSMutableArray *files = [NSMutableArray array];
    
    ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if(!asset) {
            block(files, nil);
            return;
        }
        
        ISFile *file = [[ISFile alloc] initWithAsset:asset];
        [files addObject:[file autorelease]];
    };
    
    [group enumerateAssetsUsingBlock:resultBlock];
}

+(void) getUsingAssetsLibrary:(ALAssetsLibrary*)library byUrl:(NSString*)url block:(ISFileGetBlock)block {
    ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
        if(!asset) {
            block(nil, nil);
            return;
        }
        
        ISFile *file = [[ISFile alloc] initWithAsset:asset];
        block([file autorelease], nil);
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        block(nil, error);
    };
    
    NSURL *assetUrl = [NSURL URLWithString:url];
    [library assetForURL:assetUrl resultBlock:resultBlock failureBlock:failureBlock];
}


+(void) getUsingAssetsGroup:(ALAssetsGroup*)group byIndex:(NSUInteger)index block:(ISFileGetBlock)block {
    NSInteger count = [group numberOfAssets];
    
    if(index >= count) {
        block(nil, nil);
        return;
    }
    
    __block ALAsset *result = nil;
    
    ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *asset, NSUInteger i, BOOL *stop) {
        if(!asset) {
            if(result) {
                ISFile *file = [[ISFile alloc] initWithAsset:result];
                [result release];
                
                block([file autorelease], nil);
            } else {
                block(nil, nil);
            }
            
            return;
        }
        
        result = [asset retain];
    };
    
    [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:index] options:0 usingBlock:resultBlock];
}

+(void) getUsingAlbum:(ISAlbum*)album byIndex:(NSUInteger)index block:(ISFileGetBlock)block {
    [ISFile getUsingAssetsGroup:album.assetsGroup byIndex:index block:block];
}

@synthesize name = _name;
@synthesize extension = _extension;
@synthesize url = _url;
@synthesize created = _created;
@synthesize type = _type;

@synthesize asset = _asset;

-(id) initWithAsset:(ALAsset*)asset {
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    NSString *url = [representation.url absoluteString];
    
    if(self = [super init]) {
        self->_name = [[representation filename] retain];
        self->_extension = [[[self->_name pathExtension] lowercaseString] retain];
        self->_url = [url retain];
        self->_created = [[asset valueForProperty:ALAssetPropertyDate] retain];
        self->_type = [[[asset valueForProperty:ALAssetPropertyType] substringFromIndex:[@"ALAssetType" length]] retain];
        self->_asset = [asset retain];
    }
    
    return self;
}

-(NSData*) getThumbnailWithSize:(ISImageSize)size sizeOption:(ISImageScaleMode)mode
                 representation:(ISImageRepresentation)representation {
    
    ALAssetRepresentation *assetRepresentation = [_asset defaultRepresentation];
    CGImageRef image = [assetRepresentation fullResolutionImage];
    
    return ISImageScale(image, size, mode, representation);
}

-(NSData*) getThumbnail:(ISImageRepresentation)representation {
    return [self getThumbnailWithSize:DEFAULT_THUMBNAIL_SIZE sizeOption:DEFAULT_THUMBNAIL_MODE representation:representation];
}

-(NSData*) getImage:(ISImageRepresentation)representation {
    ALAssetRepresentation *assetRepresentation = [_asset defaultRepresentation];
    return ISImageGetData([assetRepresentation fullResolutionImage], representation);
}

-(NSUInteger) getDataLength {
    return [_asset defaultRepresentation].size;
}

-(NSData*) getData {
    return [self getDataFromOffset:0 length:[self getDataLength]];
}

-(NSData*) getDataFromOffset:(NSUInteger)offset length:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    ALAssetRepresentation *representation = [_asset defaultRepresentation];
    NSError *error = nil;
    
    uint8_t *buffer = [data mutableBytes];
    
    [representation getBytes:buffer fromOffset:offset length:length error:&error];
    
    if(error) {
        return nil;
    }
    
    return data;
}

-(NSDictionary*) toDictionary {
    return @{
        @"name" : self.name,
        @"url": self.url,
        @"created": [self.created description],
        @"type": self.type
    };
}

-(NSDictionary*) toDictionary:(NSDictionary*)dictionary {
    return [[self toDictionary] mergeWithEntriesFromDictionary:dictionary];
 }

-(void) dealloc {
    [self->_name release];
    [self->_extension release];
    [self->_url release];
    [self->_created release];
    [self->_type release];
    [self->_asset release];
    
    [super dealloc];
}
@end
