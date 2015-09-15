//
//  UIApplication+addition.m
//  Closer
//
//  Created by Max on 14/09/15.
//
//

#import "UIApplication+addition.h"

static NSUInteger __idleTimerCount = 0;

@implementation UIApplication (addition)

- (void)enableIdleTimer
{
	++__idleTimerCount;
	self.idleTimerDisabled = NO;
}

- (void)disableIdleTimer
{
	__idleTimerCount = MAX(0, __idleTimerCount - 1);
	if (__idleTimerCount == 0) {
		self.idleTimerDisabled = YES;
	}
}

@end
