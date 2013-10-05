//
//  Server.h
//  iServe
//
//  Created by Mirza Kapetanovic on 9/27/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

@interface ISServer : NSObject
-(void) getPublicFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) getAlbums:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) getFiles:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) getAlbumThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response;

-(void) getFileThumbnail:(HttpServerRequest *)request response:(HttpServerResponse *)response;
-(void) getFileImage:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) getFileData:(HttpServerRequest*)request response:(HttpServerResponse*)response;

-(void) close;
-(void) listenOnPort:(NSInteger)port;
@end
