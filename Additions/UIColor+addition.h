//
//  UIColor+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//


@interface UIColor(addition)

+ (UIColor *)defaultTintColor;

+ (UIColor *)backgroundColorForStyle:(CountdownStyle)style;
+ (UIColor *)textColorForStyle:(CountdownStyle)style;

/*
- (UIColor *)invertedColor;
- (CGFloat)redComponent;
- (CGFloat)greenComponent;
- (CGFloat)blueComponent;
- (CGFloat)alphaComponent;
*/

@end
