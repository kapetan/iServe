//
//  NSDictionary+ISCollections.m
//  iServe
//
//  Created by Mirza Kapetanovic on 10/4/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "NSDictionary+ISCollection.h"

@implementation NSDictionary (ISCollection)
-(NSDictionary*) mergeWithEntriesFromDictionary:(NSDictionary*)dictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:self];
    [result addEntriesFromDictionary: dictionary];
    
    return result;
}
@end
