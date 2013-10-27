//
//  ISQueue.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/26/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "ISQueue.h"

@implementation ISQueue {
    NSMutableArray *_queue;
    NSInteger _available;
}

-(id) init {
    return [self initWithConcurrency:1];
}

-(id) initWithConcurrency:(NSInteger)concurrency {
    if(self = [super init]) {
        self->_available = concurrency;
        self->_queue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(NSInteger) count {
    return [_queue count];
}

-(void) runWithObject:(id)object {
    [self completed];
}

-(void) pushObject:(id)object {
    [_queue addObject:object];
    [self dispatch];
}

-(void) dispatch {
    if(!_available || !_queue.count) {
        return;
    }
    
    id obj = [[_queue objectAtIndex:0] retain];
    [_queue removeObjectAtIndex:0];
    
    _available--;
    
    [self runWithObject:obj];
    [obj release];
}

-(void) completed {
    _available++;
    [self dispatch];
}

-(void) dealloc {
    [_queue release];
    
    [super dealloc];
}
@end
