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
	BOOL _cancel, _animating;
}

@property (nonatomic, strong) UIView * selectedBackgroundView;
@property (nonatomic, strong) CAShapeLayer * progressLayer;

@end

@implementation TimerView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		const CGFloat width = MIN(self.frame.size.width, self.frame.size.height);
		_selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
		_selectedBackgroundView.userInteractionEnabled = NO;
		_selectedBackgroundView.alpha = 0.;
		[self addSubview:_selectedBackgroundView];
		
		_progressLayer = [CAShapeLayer layer];
		_progressLayer.frame = self.bounds;
		[_progressLayer setNeedsDisplayOnBoundsChange:YES];
		_progressLayer.fillColor = NULL;
		_progressLayer.lineWidth = 4;
		[self.layer addSublayer:_progressLayer];
		
		[self setProgression:0 animated:NO]; // Finish |progressLayer| initialization (with no progression)
	}
	return self;
}

- (void)setProgression:(CGFloat)progression
{
	[self setProgression:progression animated:NO];
}

- (void)setProgression:(CGFloat)progression animated:(BOOL)animated
{
	CGMutablePathRef mPath = CGPathCreateMutable();
	const CGFloat border = 4.;
	const CGFloat width = MIN(self.frame.size.width, self.frame.size.height);
	const CGPoint center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
	CGPathAddArc(mPath, NULL, center.x, center.y, (width - border) / 2, -M_PI_2, 2 * M_PI * progression - M_PI_2, 0);
	_progressLayer.path = mPath;
	
	if (animated && progression > 0) {
		_progressLayer.speed = 1.0;
		CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
		animation.duration = 1;
		animation.fromValue = @(_progression / progression);
		animation.toValue = @1;
		[_progressLayer addAnimation:animation forKey:@"strokeEnd"];
	}
	
	_progression = progression;
}

- (void)cancelProgressionAnimation
{
	if (_progressLayer.speed > 0) {
		CFTimeInterval pausedTime = [_progressLayer convertTime:CACurrentMediaTime() fromLayer:nil];
		_progressLayer.speed = 0;
		_progressLayer.timeOffset = pausedTime;
	}
}

- (void)setTintColor:(UIColor *)tintColor
{
	_tintColor = tintColor;
	self.selectedBackgroundView.backgroundColor = [tintColor colorWithAlphaComponent:0.333];
	self.progressLayer.strokeColor = tintColor.CGColor;
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

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	_progressLayer.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect
{
	const CGFloat border = 4.;
	CGFloat length = MIN(rect.size.width, rect.size.height);
	CGFloat topMargin = ceilf((rect.size.height - length) / 2.);
	CGFloat leftMargin = ceilf((rect.size.width - length) / 2.);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect frame = CGRectMake(leftMargin + border/2, topMargin + border/2, length - border, length - border);
	CGContextAddEllipseInRect(context, frame);
	
	[[_tintColor colorWithAlphaComponent:0.333] setStroke];
	CGContextSetLineWidth(context, border);
	CGContextStrokePath(context);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView * view = [super hitTest:point withEvent:event];
	if (view == self) {
		const CGPoint center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
		CGFloat length = MIN(self.frame.size.width, self.frame.size.height);
		if (DISTANCE(center, point) > length/2)
			return self.superview;
	}
	return view;
}

@end
