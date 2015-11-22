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
	switch (style) {
		case CountdownStyleDay:		return [UIColor whiteColor];
		case CountdownStyleDawn:		return [UIColor colorWithR:74 G:74 B:74];
		case CountdownStyleOasis:	return [UIColor colorWithR:40 G:65 B:164];
		case CountdownStyleSpring:	return [UIColor colorWithR:126 G:211 B:33];
		case CountdownStyleNight:
		default:					return [UIColor colorWithR:34 G:34 B:34];
	}
}

+ (UIColor *)textColorForStyle:(CountdownStyle)style
{
	switch (style) {
		case CountdownStyleDay:		return [UIColor colorWithR:74 G:74 B:74];
		case CountdownStyleDawn:		return [UIColor colorWithR:85 G:175 B:255];
		case CountdownStyleOasis:	return [UIColor colorWithR:126 G:211 B:33];
		case CountdownStyleSpring:	return [UIColor colorWithR:6 G:20 B:158];
		case CountdownStyleNight:
		default:					return [UIColor whiteColor];
	}
}

@end
