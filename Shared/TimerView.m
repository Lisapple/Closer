//
//  TimerView.m
//  Timer
//
//  Created by Maxime Leroy on 6/17/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "TimerView.h"

@implementation TimerView

@synthesize progression = _progression;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setProgression:(CGFloat)progression
{
	_progression = progression;
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGFloat border = 10.;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGFloat radius = rect.size.width;
	CGRect frame = CGRectMake((int)((rect.size.width - radius) / 2.), (int)((rect.size.height - radius) / 2.), radius, radius);
	
	CGContextSaveGState(context);
	{
		CGContextSetShadowWithColor(context, CGSizeMake(0., 1.), 0., [UIColor colorWithWhite:1. alpha:0.5].CGColor);
		
		CGContextAddEllipseInRect(context, frame);
		CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
		CGContextFillPath(context);
	}
	CGContextRestoreGState(context);
	
	CGContextAddEllipseInRect(context, frame);
	CGContextClip(context);
	
	CGPoint center = CGPointMake(rect.size.width / 2., rect.size.height / 2.);
	CGContextAddArc(context, center.x, center.y, radius, -M_PI_2, 2 * M_PI * _progression - M_PI_2, 0);
	CGContextAddLineToPoint(context, center.x, center.y);
	
	CGContextClosePath(context);
	
	CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
	CGContextFillPath(context);
	
	
	CGContextSetShadowWithColor(context, CGSizeMake(0., 1.), 10., [UIColor blackColor].CGColor);
	
	radius -= border * 2.;
	frame = CGRectMake((int)((rect.size.width - radius) / 2.), (int)((rect.size.height - radius) / 2.), radius, radius);
	
	CGContextAddEllipseInRect(context, frame);
	
	UIColor * color = (self.isHighlighted) ? [UIColor lightGrayColor] : [UIColor colorWithWhite:0.85 alpha:1.]; // Draw the inner circle as light gray when highlighted, 85% white else
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillPath(context);
}

@end
