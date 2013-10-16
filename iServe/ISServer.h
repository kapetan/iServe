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

NSString *AssetsPath(NSString *path);
NSString *AbsoluteUrl(HttpServerRequest *request, NSString *path, NSDictionary *query);

NSDictionary *SerializeDirecotry(NSString *path, BOOL hidden, NSError **error);

void RenderData(HttpServerResponse *response, HttpStatusCode status, NSData *body);
void RenderString(HttpServerResponse *response, HttpStatusCode status, NSString *body);
void RenderJson(HttpServerResponse *response, HttpStatusCode status, id body);

void StreamFileData(HttpServerResponse *response, ISFile *file, NSUInteger offset);

BOOL ServerError(HttpServerResponse *response, NSError *error);
BOOL EmptyParameter(HttpServerResponse *response, id parameter);
BOOL ResourceNotFound(HttpServerResponse *response, id resource);

@interface ISServer : NSObject
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
