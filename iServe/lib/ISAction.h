//
//  ISAction.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/19/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ISActionBlock)(void);

@interface ISAction : NSObject
+(void) executeBlockOnThread:(NSThread*)thread waitUntilDone:(BOOL)wait block:(ISActionBlock)block;

-(id) initWithBlock:(ISActionBlock)block;

-(void) execute;
-(void) executeOnThread:(NSThread*)thread waitUntilDone:(BOOL)wait;
@end
