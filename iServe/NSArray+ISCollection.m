//
//  Utils.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/3/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "NSArray+ISCollection.h"

@implementation NSArray (ISCollection)
-(NSArray*) mapObjectUsingBlock:(id (^)(id, NSUInteger))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
        [result addObject:block(obj, i)];
    }];
    
    return result;
}
@end
