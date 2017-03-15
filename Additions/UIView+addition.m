//
//  UIView+addition.m
//  Closer
//
//  Created by Max on 3/22/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UIView+addition.h"

@implementation UIView (addition)

- (CGPoint)origin
{
	return self.frame.origin;
}

- (void)setOrigin:(CGPoint)newOrigin
{
	if (!CGPointEqualToPoint(newOrigin, self.frame.origin))
		self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)x
{
	return self.frame.origin.x;
}

- (void)setX:(CGFloat)newX
{
	if (self.frame.origin.x != newX)
		self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)y
{
	return self.frame.origin.y;
}

- (void)setY:(CGFloat)newY
{
	if (self.frame.origin.y != newY)
		self.frame = CGRectMake(self.frame.origin.x, newY, self.frame.size.width, self.frame.size.height);
}

- (void)addParallaxEffect:(ParallaxAxis)axis offset:(CGFloat)offset
{
	NSMutableArray <UIMotionEffect *> * effects = [NSMutableArray arrayWithCapacity:2];
	
	UIInterpolatingMotionEffect * motionEffect = nil;
	if (axis & ParallaxAxisHorizontal) {
		motionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
																	   type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
		motionEffect.minimumRelativeValue = @(-offset);
		motionEffect.maximumRelativeValue = @(offset);
		[effects addObject:motionEffect];
	}
	
	if (axis & ParallaxAxisVertical) {
		motionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
																	   type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
		motionEffect.minimumRelativeValue = @(-offset);
		motionEffect.maximumRelativeValue = @(offset);
		[effects addObject:motionEffect];
	}
	
	UIMotionEffectGroup * group = [[UIMotionEffectGroup alloc] init];
	group.motionEffects = effects;
	[self addMotionEffect:group];
}

@end
