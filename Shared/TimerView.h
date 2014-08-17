//
//  TimerView.h
//  Timer
//
//  Created by Maxime Leroy on 6/17/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerView : UIControl

@property (nonatomic, assign) CGFloat progression;
@property (nonatomic, assign) UIColor * tintColor;

- (void)setProgression:(CGFloat)progression animated:(BOOL)animated;

@end
