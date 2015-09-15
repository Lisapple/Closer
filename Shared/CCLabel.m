//
//  CCLabel.m
//  Closer
//
//  Created by Maxime on 7/30/14.
//
//

#import "CCLabel.h"

@implementation CCLabel

@synthesize animatedText = _animatedText;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CCLabel *)copy
{
	CCLabel * label = [[self.class alloc] initWithFrame:self.frame];
	label.backgroundColor = self.backgroundColor;
	label.text = self.text;
	label.font = self.font;
	label.textColor = self.textColor;
	label.textAlignment = self.textAlignment;
	return label;
}

- (NSString *)animatedText
{
	return self.text;
}

- (void)setAnimatedText:(NSString *)animatedText
{
	_animatedText = animatedText;
	[self setText:animatedText animated:YES];
}

- (void)setText:(NSString *)text animated:(BOOL)animated
{
	if (animated && ![text isEqualToString:self.text]) {
		CCLabel * labelCopy = self.copy;
		[self.superview addSubview:labelCopy];
		labelCopy.text = self.text;
		labelCopy.alpha = 1.;
		
		self.text = text;
		self.alpha = 0.;
		
		[UIView animateWithDuration:0.25
							  delay:0.
							options:(UIViewAnimationOptionCurveEaseIn)
						 animations:^{ labelCopy.alpha = 0.; }
						 completion:^(BOOL finished) { [labelCopy removeFromSuperview]; }];
		[UIView animateWithDuration:0.25
							  delay:0.
							options:(UIViewAnimationOptionCurveEaseOut)
						 animations:^{ self.alpha = 1.; }
						 completion:NULL];
	} else {
		self.text = text;
	}
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
