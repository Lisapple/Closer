//
//  TimerView.m
//  Timer
//
//  Created by Maxime Leroy on 6/17/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "TimerView.h"

#import "NSObject+additions.h"

@interface TimerView ()
{
	NSUInteger animationIdentifier;
	BOOL _cancel, _animating;
}
@end

@implementation TimerView

- (void)setProgression:(CGFloat)progression
{
	_progression = progression;
	[self setNeedsDisplay];
}

- (void)setProgression:(CGFloat)finalProgression animated:(BOOL)animated
{
	if (animated && finalProgression > _progression) {
		if (!_animating) {
			_cancel = NO;
			_animating = YES;
			float startProgression = _progression;
			animationIdentifier = [NSObject animateWithDuration:1.
							   animations:^(float progression) {
								   dispatch_async(dispatch_get_main_queue(), ^{
									   _progression = CLAMP(startProgression, progression, finalProgression);
									   [self setNeedsDisplay];
								   });
							   }
							   completion:^{ _animating = NO; }];
		}
	} else {
		self.progression = finalProgression;
	}
}

- (void)cancelProgressionAnimation
{
	[NSObject cancelAnimationWithIdentifier:animationIdentifier];
	_animating = NO;
}

- (void)setTintColor:(UIColor *)tintColor
{
	_tintColor = tintColor;
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	super.highlighted = highlighted;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat border = 4.;
    CGFloat length = MIN(rect.size.width, rect.size.height);
    CGFloat topMargin = ceilf((rect.size.height - length) / 2.);
    CGFloat leftMargin = ceilf((rect.size.width - length) / 2.);
	CGRect innerFrame = CGRectMake(leftMargin + border,
                                   topMargin + border,
								   length - 2. * border,
								   length - 2. * border);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw the outer ring (with |tintColor|)
	CGContextSaveGState(context);
	{
        
		CGRect outerFrame = CGRectMake(leftMargin, topMargin, length, length);
		CGContextAddEllipseInRect(context, outerFrame);
		CGContextSetFillColorWithColor(context, [_tintColor colorWithAlphaComponent:0.333].CGColor);
		
		CGContextAddEllipseInRect(context, innerFrame);
		CGContextEOClip(context);
		
		CGContextFillRect(context, rect);
		
		CGPoint center = CGPointMake(rect.size.width / 2., rect.size.height / 2.);
		CGContextAddArc(context, center.x, center.y, rect.size.width, -M_PI_2, 2 * M_PI * _progression - M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		
		CGContextClosePath(context);
		
		CGContextSetFillColorWithColor(context, _tintColor.CGColor);
		CGContextFillPath(context);
	}
	CGContextRestoreGState(context);
	
	if (self.highlighted) {
		CGContextAddEllipseInRect(context, innerFrame);
		CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1. alpha:0.3].CGColor);
		CGContextFillPath(context);
	}
}

@end
