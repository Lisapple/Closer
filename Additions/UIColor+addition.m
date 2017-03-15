//
//  UIColor+addition.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UIColor+addition.h"

@implementation UIColor(addition)

+ (UIColor *)defaultTintColor
{
	return [UIColor colorWithWhite:0.25 alpha:1.];
}

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue
{
	return [UIColor colorWithRed:(red / 255.) green:(green / 255.) blue:(blue / 255.) alpha:1.];
}

+ (UIColor *)backgroundColorForStyle:(CountdownStyle)style
{
	UIColor * backgroundColor = [UIColor colorWithR:34 G:34 B:34];
	switch (style) {
		case CountdownStyleDay:		backgroundColor = [UIColor whiteColor]; break;
		case CountdownStyleDawn:	backgroundColor = [UIColor colorWithR:62 G:62 B:62]; break;
		case CountdownStyleOasis:	backgroundColor = [UIColor colorWithR:40 G:65 B:164]; break;
		case CountdownStyleSpring:	backgroundColor = [UIColor colorWithR:126 G:211 B:33]; break;
		case CountdownStyleNight:
		default: break;
	}
	if (UIAccessibilityDarkerSystemColorsEnabled())
		return CountdownStyleHasDarkContent(style) ? backgroundColor.lighten : backgroundColor.darken;
	return backgroundColor;
}

+ (UIColor *)textColorForStyle:(CountdownStyle)style
{
	UIColor * textColor = [UIColor whiteColor];
	switch (style) {
		case CountdownStyleDay:		textColor = [UIColor colorWithR:74 G:74 B:74]; break;
		case CountdownStyleDawn:	textColor = [UIColor colorWithR:90 G:170 B:240]; break;
		case CountdownStyleOasis:	textColor = [UIColor colorWithR:105 G:198 B:13]; break;
		case CountdownStyleSpring:	textColor = [UIColor colorWithR:0 G:39 B:153]; break;
		case CountdownStyleNight:
		default: break;
	}
	if (UIAccessibilityDarkerSystemColorsEnabled())
		return CountdownStyleHasDarkContent(style) ? textColor.darken : textColor.lighten;
	return textColor;
}

#pragma mark - Interpolations

#define CLIP(A, X, B) ( MAX(A, MIN(X, B)) )

+ (UIColor *)backgroundColorForStyles:(const CountdownStyle[])styles indexValue:(CGFloat)index
{
	CGFloat fract = index - floor(index);
	UIColor * startColor = [UIColor backgroundColorForStyle:styles[(int)index]];
	UIColor * endColor = [UIColor backgroundColorForStyle:styles[(int)index+1]];
	return [startColor interpolateColor:endColor progress:fract];
}

+ (UIColor *)textColorForStyles:(const CountdownStyle[])styles indexValue:(CGFloat)index
{
	CGFloat fract = index - floor(index);
	UIColor * startColor = [UIColor textColorForStyle:styles[(int)index]];
	UIColor * endColor = [UIColor textColorForStyle:styles[(int)index+1]];
	return [startColor interpolateColor:endColor progress:fract];
}

- (UIColor *)interpolateColor:(UIColor *)color progress:(CGFloat)progress
{
	progress = CLIP(0, progress, 1);
	CGFloat r1, b1, g1, a1; [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
	CGFloat r2, b2, g2, a2; [color getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
#define LERP(A, X, B) ( A + X*(B-A) )
	return [UIColor colorWithRed:LERP(r1, progress, r2)
						   green:LERP(g1, progress, g2)
							blue:LERP(b1, progress, b2)
						   alpha:LERP(a1, progress, a2)];
#undef LERP
}

#undef CLIP

#pragma mark - Brightness control

- (UIColor *)lighten
{
	CGFloat h, s, b, a;
	[self getHue:&h saturation:&s brightness:&b alpha:&a];
	s *= 0.8; b *= 1.4;
	return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
}

- (UIColor *)darken
{
	CGFloat h, s, b, a;
	[self getHue:&h saturation:&s brightness:&b alpha:&a];
	s *= 1.2; b *= 0.6;
	return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
}

@end
