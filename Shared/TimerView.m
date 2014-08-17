//
//  TimerView.m
//  Timer
//
//  Created by Maxime Leroy on 6/17/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "TimerView.h"

#import "NSObject+additions.h"

@implementation TimerView

@synthesize progression = _progression;

- (void)setProgression:(CGFloat)progression
{
	_progression = progression;
	[self setNeedsDisplay];
}

- (void)setProgression:(CGFloat)progression animated:(BOOL)animated
{
	if (animated && progression > _progression) {
		float startProgression = _progression;
		[NSObject animationBlock:^(float t) {
			_progression = CLAMP(startProgression, progression, t);
			[self setNeedsDisplay];
		}
						duration:1.];
	} else {
		self.progression = progression;
	}
}

- (void)setTintColor:(UIColor *)tintColor
{
	_tintColor = tintColor;
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGFloat border = 4.;
	CGRect innerFrame = CGRectMake(border, border,
								   rect.size.width - 2. * border,
								   rect.size.width - 2. * border);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw the outer ring (with |tintColor|)
	CGContextSaveGState(context);
	{
		CGRect outerFrame = CGRectMake(0., 0., rect.size.width, rect.size.width);
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
