//
//  UIColor+addition.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UIColor+addition.h"


@implementation UIColor(addition)

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

/*
- (UIColor *)invertedColor
{
	return [UIColor colorWithRed:(1. - [self redComponent]) 
						   green:(1. - [self greenComponent]) 
							blue:(1. - [self blueComponent]) 
						   alpha:[self alphaComponent]];
}

- (CGFloat)redComponent
{
	// RGBA Component
	const CGFloat * components = CGColorGetComponents(self.CGColor);
	return components[0];
}

- (CGFloat)greenComponent
{
	// RGBA Component
	const CGFloat * components = CGColorGetComponents(self.CGColor);
	return components[1];
}

- (CGFloat)blueComponent
{
	// RGBA Component
	const CGFloat * components = CGColorGetComponents(self.CGColor);
	return components[2];
}

- (CGFloat)alphaComponent
{
	// RGBA Component
	const CGFloat * components = CGColorGetComponents(self.CGColor);
	return components[3];
}

- (NSString *)_description
{
	return [NSString stringWithFormat:@"<Color 0x%x R:%.3f, G:%.3f, B:%.3f, A:%.3f>", self, [self redComponent], [self greenComponent], [self blueComponent], [self alphaComponent]];
}
*/

@end
