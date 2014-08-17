//
//  UIColor+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PageView.h"

@interface UIColor(addition)

+ (UIColor *)groupedTableViewBackgroundColor;
+ (UIColor *)defaultTintColor;
+ (UIColor *)doneButtonColor;

+ (UIColor *)backgroundColorForPageStyle:(PageViewStyle)style;
+ (UIColor *)textColorForPageStyle:(PageViewStyle)style;

/*
- (UIColor *)invertedColor;
- (CGFloat)redComponent;
- (CGFloat)greenComponent;
- (CGFloat)blueComponent;
- (CGFloat)alphaComponent;
*/

@end
