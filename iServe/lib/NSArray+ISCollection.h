//
//  Utils.h
//  iServe
//
//  Created by Mirza Kapetanovic on 10/3/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ISCollection)
-(NSArray*) mapObjectsUsingBlock:(id (^)(id obj, NSUInteger i))block;
@end
