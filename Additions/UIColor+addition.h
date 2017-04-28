//
//  UIColor+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import AVFoundation;

#import "Countdown.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIColor(addition)

+ (UIColor *)defaultTintColor;

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue;

+ (nullable UIColor *)backgroundColorForStyle:(CountdownStyle)style;
+ (nullable UIColor *)backgroundColorForStyle:(CountdownStyle)style alpha:(CGFloat)alpha;

+ (nullable UIColor *)textColorForStyle:(CountdownStyle)style;

/// Returns a color by interpolation style background colors for index value; `indexValue' *must* be between [0, styles.count-1]
+ (UIColor *)backgroundColorForStyles:(const CountdownStyle[_Nonnull])styles indexValue:(CGFloat)index;

/// Returns a color by interpolation style text colors for index value; `indexValue' *must* be between [0, styles.count-1]
+ (UIColor *)textColorForStyles:(const CountdownStyle[_Nonnull])styles indexValue:(CGFloat)index;

/// Returns a color by interpolation with self and color for value between [0, 1] (others values clipped); 0 means same color that sender, 1 means same as `color`
- (UIColor *)interpolateColor:(UIColor *)color progress:(CGFloat)progress;

+ (UIColor *)interpolateColors:(NSArray <UIColor *> *)colors locations:(const CGFloat [_Nonnull])locations progress:(CGFloat)progress;

- (UIColor *)lighten;
- (UIColor *)darken;

@end

NS_ASSUME_NONNULL_END
