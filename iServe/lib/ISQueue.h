//
//  ISQueue.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/26/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISQueue : NSObject
@property (nonatomic, readonly) NSInteger count;

-(id) initWithConcurrency:(NSInteger)concurrency;

-(void) runWithObject:(id)object;
-(void) pushObject:(id)object;

-(void) dispatch;
-(void) completed;
@end
