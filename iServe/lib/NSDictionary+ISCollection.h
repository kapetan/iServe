//
//  NSDictionary+ISCollections.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/4/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ISCollection)
-(NSDictionary*) mergeWithEntriesFromDictionary:(NSDictionary*)dictionary;
@end
