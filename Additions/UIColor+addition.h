//
//  UIColor+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface UIColor(addition)

+ (UIColor *)defaultTintColor;

+ (UIColor *)backgroundColorForStyle:(CountdownStyle)style;
+ (UIColor *)textColorForStyle:(CountdownStyle)style;

/// Returns a color by interpolation style background colors for index value; `indexValue' *must* be between [0, styles.count-1]
+ (UIColor *)backgroundColorForStyles:(const CountdownStyle[])styles indexValue:(CGFloat)index;

/// Returns a color by interpolation style text colors for index value; `indexValue' *must* be between [0, styles.count-1]
+ (UIColor *)textColorForStyles:(const CountdownStyle[])styles indexValue:(CGFloat)index;

/// Returns a color by interpolation with self and color for value between [0, 1] (others values clipped)
- (UIColor *)interpolateColor:(UIColor *)color progress:(CGFloat)progress;

- (UIColor *)lighten;
- (UIColor *)darken;

@end

NS_ASSUME_NONNULL_END
