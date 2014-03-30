//
//  UIView+addition.m
//  Closer
//
//  Created by Max on 3/22/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UIView+addition.h"


@implementation UIView (addition)

- (void)setOrigin:(CGPoint)newOrigin
{
	if (!CGPointEqualToPoint(newOrigin, self.frame.origin)) {
		self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
	}
}

- (void)setX:(CGFloat)newX
{
	if (self.frame.origin.x != newX) {
		self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
	}
}

- (void)setY:(CGFloat)newY
{
	if (self.frame.origin.y != newY) {
		self.frame = CGRectMake(self.frame.origin.x, newY, self.frame.size.width, self.frame.size.height);
	}
}

@end
