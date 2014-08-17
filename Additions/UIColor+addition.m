//
//  UIColor+addition.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UIColor+addition.h"

@implementation UIColor(addition)

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue
{
	return [UIColor colorWithRed:(red / 255.) green:(green / 255.) blue:(blue / 255.) alpha:1.];
}

+ (UIColor *)groupedTableViewBackgroundColor
{
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"grouped_tableview_background"]];
}

+ (UIColor *)defaultTintColor
{
	return [UIColor colorWithWhite:0.25 alpha:1.];
}

+ (UIColor *)doneButtonColor
{
	return [UIColor colorWithRed:0.6 green:0.6 blue:1. alpha:1.];
}

+ (UIColor *)backgroundColorForPageStyle:(PageViewStyle)style
{
	switch (style) {
		case PageViewStyleDay:		return [UIColor whiteColor];
		case PageViewStyleDawn:		return [UIColor colorWithR:74 G:74 B:74];
		case PageViewStyleOasis:	return [UIColor colorWithR:40 G:65 B:164];
		case PageViewStyleSpring:	return [UIColor colorWithR:126 G:211 B:33];
		case PageViewStyleNight:
		default:					return [UIColor colorWithR:34 G:34 B:34];
	}
}

+ (UIColor *)textColorForPageStyle:(PageViewStyle)style
{
	switch (style) {
		case PageViewStyleDay:		return [UIColor colorWithR:74 G:74 B:74];
		case PageViewStyleDawn:		return [UIColor colorWithR:85 G:175 B:255];
		case PageViewStyleOasis:	return [UIColor colorWithR:126 G:211 B:33];
		case PageViewStyleSpring:	return [UIColor colorWithR:6 G:20 B:158];
		case PageViewStyleNight:
		default:					return [UIColor whiteColor];
	}
}

@end
