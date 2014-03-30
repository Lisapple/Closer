//
//  NSObject+additions.h
//  Closer
//
//  Created by Max on 23/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (additions)

+ (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

@end
