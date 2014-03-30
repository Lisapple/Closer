//
//  NSObject+additions.m
//  Closer
//
//  Created by Max on 23/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+additions.h"

@implementation NSObject (additions)

+ (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end
