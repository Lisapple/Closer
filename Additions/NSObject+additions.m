//
//  NSObject+addition.m
//  Elsas Gone
//
//  Created by Max on 7/23/14.
//  Copyright (c) 2014 Lisacintosh. All rights reserved.
//

#import "NSObject+additions.h"

@implementation NSObject (addition)

+ (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

@end
