//
//  CCLabel.m
//  Closer
//
//  Created by Maxime on 7/30/14.
//
//

#import "CCLabel.h"

#define DefaultFontWeight UIFontWeightThin

#define FromLabelTag 1001
#define ToLabelTag 1002

@interface CCLabel ()

@property (nonatomic, strong, nullable) NSString * textValue;

@end

@implementation CCLabel

@dynamic animatedText;

- (BOOL)isOpaque
{
	return NO;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone
{
	CCLabel * label = [[self.class allocWithZone:zone] initWithFrame:self.bounds];
	label.backgroundColor = [UIColor clearColor];
	label.font = self.font;
	label.textColor = self.textColor;
	label.textAlignment = self.textAlignment;
	return label;
}

- (NSString *)animatedText
{
	return _textValue;
}

- (void)setAnimatedText:(NSString *)animatedText
{
	[self setText:animatedText animated:YES];
}

- (void)setText:(NSString *)text animated:(BOOL)animated
{
	BOOL shouldDisableAnimation = UIAccessibilityIsReduceMotionEnabled();
	animated &= !shouldDisableAnimation;
	
	if (animated && ![text isEqualToString:self.animatedText]) {
		BOOL usesMonospacedFont = ([[NSScanner scannerWithString:text] scanInt:nil]);
		if (usesMonospacedFont && [UIFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)]) // iOS 9+
			self.font = [UIFont monospacedDigitSystemFontOfSize:self.font.pointSize weight:DefaultFontWeight];
		else
			self.font = [UIFont systemFontOfSize:self.font.pointSize weight:DefaultFontWeight];
		
		NSString * const kPlaceholderString = @" "; // Placeholder for label to keep minimum width
		
		CCLabel * toLabel = self.copy;
		toLabel.tag = ToLabelTag;
		toLabel.text = text;
		toLabel.alpha = 0.;
		toLabel.font = self.font;
		[self addSubview:toLabel];
		[UIView animateWithDuration:0.25 delay:0.
							options:(UIViewAnimationOptionCurveEaseOut)
						 animations:^{ toLabel.alpha = 1.; }
						 completion:^(BOOL finished) {
							 [toLabel removeFromSuperview];
							 if ([self.text isEqualToString:kPlaceholderString]) // If text was not changed without animation
								 self.text = text;
						 }];
		
		CCLabel * fromLabel = self.copy;
		fromLabel.tag = FromLabelTag;
		fromLabel.text = _textValue;
		fromLabel.alpha = 1.;
		fromLabel.font = self.font;
		[self addSubview:fromLabel];
		[UIView animateWithDuration:0.25 delay:0.
							options:(UIViewAnimationOptionCurveEaseIn)
						 animations:^{ fromLabel.alpha = 0.; }
						 completion:^(BOOL finished) { [fromLabel removeFromSuperview]; }];
		
		self.text = kPlaceholderString;
		_textValue = text;
	} else {
		self.text = text;
		[[self viewWithTag:ToLabelTag] removeFromSuperview];
		[[self viewWithTag:FromLabelTag] removeFromSuperview];
	}
}

@end
