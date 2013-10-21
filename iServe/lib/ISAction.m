//
//  ISAction.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/19/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISAction.h"

@implementation ISAction {
    ISActionBlock _block;
}

+(void) executeBlockOnThread:(NSThread *)thread waitUntilDone:(BOOL)wait block:(ISActionBlock)block {
    ISAction *action = [[ISAction alloc] initWithBlock:block];
    [action executeOnThread:thread waitUntilDone:wait];
    
    [action release];
}

-(id) init {
    return [self initWithBlock:^{}];
}

-(id) initWithBlock:(ISActionBlock)block {
    if(self = [super init]) {
        self->_block = [block copy];
    }
    
    return self;
}

-(void) execute {
    _block();
}

-(void) executeOnThread:(NSThread*)thread waitUntilDone:(BOOL)wait {
    [self performSelector:@selector(execute) onThread:thread withObject:nil waitUntilDone:wait];
}

-(void) dealloc {
    [_block release];
    
    [super dealloc];
}
@end
