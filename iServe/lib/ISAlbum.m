//
//  Album.m
//  iServe
//
//  Created by Mirza Kapetanovic on 9/29/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISAlbum.h"
#import "ISFile.h"

#import "ISAction.h"

#import "NSDictionary+ISCollection.h"

const ALAssetsGroupType GROUP_TYPES = ALAssetsGroupAlbum | ALAssetsGroupSavedPhotos;

@implementation ISAlbum
+(void) getAllUsingAssetsLibrary:(ALAssetsLibrary*)library block:(ISAlbumAllBlock)block {
    NSMutableArray *groups = [NSMutableArray array];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if(!group) {
            block(groups, nil);
            return;
        }
        
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        ISAlbum *album = [[ISAlbum alloc] initWithAssetsLibrary:library assetsGroup:group];
        [groups addObject:[album autorelease]];
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        block(nil, error);
    };
    
    [library enumerateGroupsWithTypes:GROUP_TYPES usingBlock:resultBlock failureBlock:failureBlock];
}

+(void) getUsingAssetsLibrary:(ALAssetsLibrary*)library byUrl:(NSString*)url block:(ISAlbumGetBlock)block {
    ALAssetsLibraryGroupResultBlock resultBlock = ^(ALAssetsGroup *group) {
        if(!group) {
            block(nil, nil);
            return;
        }
        
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        ISAlbum *album = [[ISAlbum alloc] initWithAssetsLibrary:library assetsGroup:group];
        block([album autorelease], nil);
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        block(nil, error);
    };
    
    NSURL *groupUrl = [NSURL URLWithString:url];
    [library groupForURL:groupUrl resultBlock:resultBlock failureBlock:failureBlock];
}

@synthesize name = _name;
@synthesize url = _url;

@synthesize assetsLibrary = _assetsLibrary;
@synthesize assetsGroup = _assetsGroup;

-(id) initWithAssetsLibrary:(ALAssetsLibrary*)library assetsGroup:(ALAssetsGroup*)group {
    NSURL *url = [group valueForProperty:ALAssetsGroupPropertyURL];
    NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
    
    if(self = [super init]) {
        self->_name = [name retain];
        self->_url = [[url absoluteString] retain];
        self->_assetsLibrary = [library retain];
        self->_assetsGroup = [group retain];
    }
    
    return self;
}

-(void) getAllFiles:(ISAlbumAllFilesBlock)block {
    [ISFile getAllByAlbum:self block:block];
}

-(void) getFileByUrl:(NSString*)url block:(ISAlbumFileBlock)block {
    [self getAllFiles:^(NSArray *files, NSError *error) {
        if(error) {
            block(nil, error);
            return;
        }
        
        NSUInteger index = [files indexOfObjectPassingTest:^BOOL(ISFile *file, NSUInteger i, BOOL *stop) {
            return [file.url isEqualToString:url];
        }];
        
        if(index == NSNotFound) {
            block(nil, nil);
            return;
        }
        
        block([files objectAtIndex:index], nil);
    }];
}

-(void) getFileByIndex:(NSUInteger)index block:(ISAlbumFileBlock)block {
    [ISFile getUsingAlbum:self byIndex:index block:block];
}

-(NSInteger) numberOfFiles {
    return [_assetsGroup numberOfAssets];
}

-(NSDictionary*) toDictionary {
    return @{
        @"name": self.name,
        @"url": self.url,
        @"numberOfFiles": [NSNumber numberWithInt:[self numberOfFiles]]
    };
}

-(NSDictionary*) toDictionary:(NSDictionary*)dictionary {
    return [[self toDictionary] mergeWithEntriesFromDictionary:dictionary];
}

-(void) dealloc {
    [self->_name release];
    [self->_url release];
    [self->_assetsLibrary release];
    [self->_assetsGroup release];
    
    [super dealloc];
}
@end
