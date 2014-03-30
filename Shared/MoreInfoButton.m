//
//  MoreInfoButton.m
//  Closer
//
//  Created by Max on 4/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MoreInfoButton.h"


@implementation MoreInfoButton

@synthesize shadowOffset;
@synthesize _infoButton, _shadowInfoButton;

const CGFloat kHighlightAlphaValue = 0.8;

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		self.frame = frame;
		self.alpha = kHighlightAlphaValue;
		self.userInteractionEnabled = YES;
		
		self._infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
		_infoButton.showsTouchWhenHighlighted = YES;
		_infoButton.userInteractionEnabled = NO;
		[self addSubview:_infoButton];
	}
	
	return self;
}

- (void)setShadowOffset:(CGSize)offset
{
	if (!_shadowInfoButton) {
		self._shadowInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
		_shadowInfoButton.userInteractionEnabled = NO;
		[self insertSubview:_shadowInfoButton atIndex:0];
	}
	
	_shadowInfoButton.frame = CGRectMake(_infoButton.frame.origin.x + offset.width, _infoButton.frame.origin.y + offset.height,
										 _infoButton.frame.size.width, _infoButton.frame.size.height);
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
	[_infoButton addTarget:target action:action forControlEvents:controlEvents];
}

- (void)setHighlighted
{
	self.alpha = 1.;
}

- (void)setNonHighlighted
{
	self.alpha = kHighlightAlphaValue;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView * view = [super hitTest:point withEvent:event];
	if (view == self)
		[self setHighlighted];
	
	return view;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self setHighlighted];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self setNonHighlighted];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self setNonHighlighted];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[_infoButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	
	[self performSelector:@selector(setNonHighlighted) withObject:nil afterDelay:0.5];
}

@end
