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

@property (nonatomic, strong) UIView * selectedBackgroundView;

@end

@implementation TimerView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		const CGFloat width = MIN(self.frame.size.width, self.frame.size.height);
		self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
		self.selectedBackgroundView.userInteractionEnabled = NO;
		self.selectedBackgroundView.alpha = 0.;
		[self addSubview:self.selectedBackgroundView];
	}
	return self;
}

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
	self.selectedBackgroundView.backgroundColor = [tintColor colorWithAlphaComponent:0.333];
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	super.highlighted = highlighted;
	
	if (highlighted) {
		const CGFloat width = MIN(self.frame.size.width, self.frame.size.height);
		self.selectedBackgroundView.frame = CGRectMake(0, 0, width, width);
		CGPoint center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
		self.selectedBackgroundView.center = center;
		self.selectedBackgroundView.layer.cornerRadius = self.selectedBackgroundView.frame.size.height / 2.;
		[UIView animateWithDuration:0.05 animations:^{
			self.selectedBackgroundView.alpha = 1.; }];
	} else {
		[UIView animateWithDuration:0.05 animations:^{
			self.selectedBackgroundView.alpha = 0; }];
	}
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
}

@end
