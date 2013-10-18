//
//  Server.h
//  iServe
//
//  Created by Mirza Kapetanovic on 9/27/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"
#import "ISFile.h"

@class ISServer;
@class ISServerDelegate;

NSString *AssetsPath(NSString *path);
NSString *AbsoluteUrl(HttpServerRequest *request, NSString *path, NSDictionary *query);

NSDictionary *SerializeDirectory(NSString *path, BOOL hidden, NSError **error);

void StreamFileData(HttpServerResponse *response, ISFile *file, NSUInteger offset);

@protocol ISServerDelegate <NSObject>
-(void) server:(ISServer*)server errorOccurred:(NSError *)error;
-(void) serverDidClose:(ISServer*)server;
@end

@interface ISServer : NSObject
@property (nonatomic, assign) ISServerDelegate *delegate;

-(void) getPublicFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) getTemplates:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) getAlbums:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) getFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) getAlbumThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response;

-(void) getFileThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response;
-(void) getFileImage:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) getFileData:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) close;
-(void) listenOnPort:(NSInteger)port;
@end
