//
//  DurationPickerView.m
//  DurationPicker
//
//  Created by Maxime Leroy on 7/4/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "DurationPickerView.h"

@implementation _DurationMaskView

- (BOOL)isOpaque
{
	return NO;
}

- (BOOL)isUserInteractionEnabled
{
	return NO;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat width = 30.;
	CGRect frame = CGRectMake(rect.origin.x + ceilf((rect.size.width - width) / 2.), 0.,
							  width, rect.size.height);
	[[UIColor colorWithWhite:0.9 alpha:1.] setStroke];
	CGContextStrokeRect(context, frame);
	
	CGContextSetBlendMode(context, kCGBlendModeClear);
	[[UIColor clearColor] setFill];
	CGContextFillRect(context, frame);
}

- (void)setFrame:(CGRect)frame
{
	super.frame = frame;
	
	/* Force the view to redraw (iOS will upscale the view for performance propose but the arrow be will scaled as well) */
	[self setNeedsDisplay];
}

@end


@implementation _DurationScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.showsHorizontalScrollIndicator = NO;
		self.alwaysBounceHorizontal = YES;
	}
	return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
	super.contentOffset = contentOffset;
	
	/* Force the scrollView to redraw when scrolling */
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([self.touchDelegate respondsToSelector:@selector(durationScrollView:didTouchOnIndex:)]) {
		UITouch * touch = touches.anyObject;
		CGPoint location = [touch locationInView:self];
		
		const CGFloat labelWidth = 40.;
		int margin = self.frame.size.width / 2.;
		
		CGFloat touchOffset = margin + location.x - (self.frame.size.width / 2.);
		
		NSInteger index = touchOffset / labelWidth;
		[self.touchDelegate durationScrollView:self didTouchOnIndex:index];
	}
}

@end


@interface DurationPickerView ()

@property (nonatomic, strong) _DurationScrollView * scrollView;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) NSMutableArray <UILabel *> * labels;

- (void)initialize;

- (void)updateLayout;
- (void)updateScrolling;

@end

@implementation DurationPickerView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self initialize];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self initialize];
	}
	return self;
}

- (void)initialize
{
	CGRect bounds = self.bounds;
	bounds.size.height -= 2.;
	_scrollView = [[_DurationScrollView alloc] initWithFrame:bounds];
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:_scrollView];
	
	_scrollView.delegate = self;
	_scrollView.touchDelegate = self;
	
	_DurationMaskView * maskView = [[_DurationMaskView alloc] initWithFrame:self.bounds];
	maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:maskView];
}

- (UIColor *)highlightedTextColor
{
	return [UIColor colorWithWhite:0.1 alpha:1.];
}

- (UIColor *)unhighlightedTextColor
{
	return [UIColor lightGrayColor];
}

- (void)reloadData
{
	_numberOfItems = [self.dataSource numberOfNumbersInDurationPickerView:self];
	
	const CGFloat labelWidth = 40., labelHeight = 40.;
	
	if (!_labels)
		_labels = [[NSMutableArray alloc] initWithCapacity:_numberOfItems];
	
	[_labels removeAllObjects];
	
	for (int index = 0; index < _numberOfItems; index++) {
		NSInteger number = [self.dataSource durationPickerView:self numberForIndex:index];
		
		CGRect rect = CGRectMake(index * labelWidth, 2., labelWidth, labelHeight);
		UILabel * label = [[UILabel alloc] initWithFrame:rect];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = YES;
		label.textColor = (index == _selectedIndex)? [self highlightedTextColor] : [self unhighlightedTextColor];
		label.font = [UIFont boldSystemFontOfSize:17.];
		label.textAlignment = NSTextAlignmentCenter;
		label.text = [NSString stringWithFormat:@"%ld", (long)number];
		[_scrollView addSubview:label];
		[_labels addObject:label];
	}
	
	[self updateLayout];
}

- (void)updateLayout
{
	const CGFloat labelWidth = 40., labelHeight = 40.;
	_scrollView.contentSize = CGSizeMake(_numberOfItems * labelWidth, labelHeight);
	int margin = (self.frame.size.width - labelWidth) / 2.;
	_scrollView.contentInset = UIEdgeInsetsMake(0., margin, 0., margin);
	
	/* Scroll to correct position (left by default) */
	_scrollView.contentOffset = CGPointMake(_selectedIndex * labelWidth - margin, 0.);
}

- (void)setFrame:(CGRect)frame
{
	super.frame = frame;
	[self updateLayout];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
	[self selectIndex:selectedIndex animated:NO];
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated
{
	if (0 <= index && index < _numberOfItems) {
		UILabel * oldLabel = _labels[_selectedIndex];
		oldLabel.textColor = [self unhighlightedTextColor];
		
		UILabel * newLabel = _labels[index];
		newLabel.textColor = [self highlightedTextColor];
			
		_selectedIndex = index;
		
		const CGFloat labelWidth = 40.;
		int margin = self.frame.size.width / 2.;
		
		CGFloat newOffset = index * labelWidth - margin + labelWidth / 2.;
		[_scrollView setContentOffset:CGPointMake(newOffset, 0.)
							 animated:animated];
	}
}

- (void)updateScrolling
{
	const CGFloat labelWidth = 40.;
	int margin = self.frame.size.width / 2.;
	CGFloat offset = _scrollView.contentOffset.x + margin;
	
	NSInteger index = offset / labelWidth;
	
	CGFloat newOffset = index * labelWidth - margin + labelWidth / 2.;
	[_scrollView setContentOffset:CGPointMake(newOffset, 0.)
						animated:YES];
	
	if (0 <= _selectedIndex && _selectedIndex < _labels.count) {
		UILabel * oldLabel = _labels[_selectedIndex];
		oldLabel.textColor = [self unhighlightedTextColor];
	}
	
	if (0 <= index && index < _labels.count) {
		UILabel * newLabel = _labels[index];
		newLabel.textColor = [self highlightedTextColor];
	}
	
	_selectedIndex = index;
	if ([self.delegate respondsToSelector:@selector(durationPickerView:didSelectIndex:)])
		[self.delegate durationPickerView:self didSelectIndex:index];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	[self updateScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate)
		[self updateScrolling];
}

- (void)durationScrollView:(_DurationScrollView *)durationScrollView didTouchOnIndex:(NSInteger)index
{
	[self selectIndex:index animated:YES];
	if ([self.delegate respondsToSelector:@selector(durationPickerView:didSelectIndex:)])
		[self.delegate durationPickerView:self didSelectIndex:index];
}

@end
