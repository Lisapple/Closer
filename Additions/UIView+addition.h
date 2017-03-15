//
//  UIView+addition.h
//  Closer
//
//  Created by Max on 3/22/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

typedef NS_OPTIONS(NSUInteger, ParallaxAxis) {
	ParallaxAxisVertical = 1 << 0,
	ParallaxAxisHorizontal = 1 << 1
};

@interface UIView (addition)

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat x, y;

- (void)addParallaxEffect:(ParallaxAxis)axis offset:(CGFloat)offset;

@end
