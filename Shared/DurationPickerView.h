//
//  DurationPickerView.h
//  DurationPicker
//
//  Created by Maxime Leroy on 7/4/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface _DurationMaskView : UIView

@end


@class _DurationScrollView;
@protocol _DurationScrollViewDelegate <NSObject>

@optional
- (void)durationScrollView:(_DurationScrollView *)durationScrollView didTouchOnIndex:(NSInteger)index;

@end

@interface _DurationScrollView : UIScrollView
{
	UIColor * backgroundColor;
}

@property (nonatomic, strong) id <_DurationScrollViewDelegate> touchDelegate;

@end


@class DurationPickerView;
@protocol DurationPickerViewDataSource <NSObject>

- (NSInteger)numberOfNumbersInDurationPickerView:(DurationPickerView *)durationPickerView;
- (NSInteger)durationPickerView:(DurationPickerView *)durationPickerView numberForIndex:(NSInteger)index;

@end

@protocol DurationPickerViewDelegate <NSObject>

@optional
- (void)durationPickerView:(DurationPickerView *)durationPickerView didSelectIndex:(NSInteger)index;

@end

@interface DurationPickerView : UIView <UIScrollViewDelegate, _DurationScrollViewDelegate>
{
	_DurationScrollView * scrollView;
	NSInteger numberOfItems;
	NSMutableArray * labels;
}

@property (nonatomic, strong) id <DurationPickerViewDelegate> delegate;
@property (nonatomic, strong) id <DurationPickerViewDataSource> dataSource;

@property (nonatomic, assign) NSInteger selectedIndex;

- (void)reloadData;

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;

@end
