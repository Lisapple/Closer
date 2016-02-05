//
//  CCLabel.m
//  Closer
//
//  Created by Maxime on 7/30/14.
//
//

#import "CCLabel.h"

@implementation CCLabel

@dynamic animatedText;

- (instancetype)copyWithZone:(nullable NSZone *)zone
{
	CCLabel * label = [[self.class allocWithZone:zone] initWithFrame:self.frame];
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
	} else
		self.text = text;
}

@end
