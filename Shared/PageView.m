//
//  PageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "PageView.h"

@implementation PageView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)update
{
	/* Subsclasses must implement it */
}

- (NSTimeInterval)minDurationBeforeIdle
{
	NSTimeInterval minDurationBeforeIdle = 3 * 60;
	if ([NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)] &&
		[NSProcessInfo processInfo].isLowPowerModeEnabled) {
		minDurationBeforeIdle = 30;
	}
	return minDurationBeforeIdle;
}

- (void)viewWillShow:(BOOL)animated
{
	_isViewShown = YES;
}

- (void)viewDidHide:(BOOL)animated
{
	_isViewShown = NO;
}

- (void)handleDoubleTap
{
	if ([self.delegate respondsToSelector:@selector(pageViewDidDoubleTap:)])
		[self.delegate pageViewDidDoubleTap:self];
}

@end
