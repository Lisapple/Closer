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
	
	if (TARGET_IS_IOS7_OR_LATER()) {
		CGFloat width = 30.;
		CGRect frame = CGRectMake(rect.origin.x + ceilf((rect.size.width - width) / 2.), 0.,
								  width, rect.size.height);
		[[UIColor colorWithWhite:0.9 alpha:1.] setStroke];
		CGContextStrokeRect(context, frame);
		
		CGContextSetBlendMode(context, kCGBlendModeClear);
		[[UIColor clearColor] setFill];
		CGContextFillRect(context, frame);
		
	} else {
		
		CGFloat border = 1.;
		CGRect frame = CGRectMake(border, border, rect.size.width - border * 2, rect.size.height - border * 2);
		
		float bottomRadius = 8., topRadius = 0.;
		CGSize arrowSize = CGSizeMake(20., 10.);
		float x = frame.origin.x, y = frame.origin.y, width = frame.size.width, height = frame.size.height;
		
		CGContextSaveGState(context);
		{
			CGContextBeginPath(context);
			/* Start at right-up corner*/
			CGContextMoveToPoint(context, x, y + topRadius);
			CGContextAddArcToPoint(context, x, y, x + topRadius, y, topRadius);
			
			/* Add the arrow (at the top) */
			CGContextAddLineToPoint(context, x + width / 2. - arrowSize.width / 2., y);
			CGContextAddLineToPoint(context, x + width / 2., y + arrowSize.height);
			CGContextAddLineToPoint(context, x + width / 2. + arrowSize.width / 2., y);
			
			CGContextAddArcToPoint(context, x + width, y, x + width, topRadius, topRadius);
			CGContextAddArcToPoint(context, x + width, height + y, x + width - bottomRadius, height + y, bottomRadius);
			CGContextAddArcToPoint(context, x, height + y, x, y + height - bottomRadius, bottomRadius);
			CGContextClosePath(context);
			CGContextClip(context);
			
			CGContextSetBlendMode(context, kCGBlendModeClear);
			[[UIColor blueColor] setFill];//[[UIColor clearColor] setFill];
			CGContextFillRect(context, frame);
		}
		CGContextRestoreGState(context);
		
		CGContextSetBlendMode(context, kCGBlendModeNormal);
		CGContextSaveGState(context);
		{
			CGContextSetShadowWithColor(context, CGSizeMake(0., 1.), 3., [UIColor colorWithWhite:0. alpha:0.333].CGColor);
			
			// @TODO: Create a rounded arrow for iOS 7+
			
			CGContextBeginPath(context);
			/* Start at right-up corner*/
			CGContextMoveToPoint(context, x, y);
			
			/* Add the arrow (at the top) */
			CGContextAddLineToPoint(context, x + width / 2. - arrowSize.width / 2., y);
			CGContextAddLineToPoint(context, x + width / 2., y + arrowSize.height);
			CGContextAddLineToPoint(context, x + width / 2. + arrowSize.width / 2., y);
			
			CGContextAddLineToPoint(context, x + width, y);
			CGContextAddLineToPoint(context, x + width, y - 10.);
			CGContextAddLineToPoint(context, x, y - 10.);
			
			CGContextClosePath(context);
			
			[[UIColor colorWithWhite:(247. / 255.) alpha:1.] setFill];
			CGContextFillPath(context);
		}
		CGContextRestoreGState(context);
	}
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	/* Force the view to redraw (iOS will upscale the view for performance propose but the arrow be will scaled as well) */
	[self setNeedsDisplay];
}

@end


@implementation _DurationScrollView

@synthesize touchDelegate = _touchDelegate;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		self.showsHorizontalScrollIndicator = NO;
		self.alwaysBounceHorizontal = YES;
		//self.backgroundColor =
		
		if (!TARGET_IS_IOS7_OR_LATER()) {
			UIImage * image = [UIImage imageNamed:@"picker-background"];
			backgroundColor = [UIColor colorWithPatternImage:image];
		}
	}
    return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	/* Clear the border (with round corner) */
	if (TARGET_IS_IOS7_OR_LATER()) {
		
	} else {
		
		CGFloat border = 0.;
		CGRect frame = CGRectMake(border + self.contentOffset.x, border, rect.size.width - border * 2, rect.size.height - border * 2);
		
		float bottomRadius = 8., topRadius = 0.;
		float x = frame.origin.x, y = frame.origin.y, width = frame.size.width, height = frame.size.height;
		CGContextBeginPath(context);
		/* Start at right-up corner*/
		CGContextMoveToPoint(context, x, y + topRadius);
		CGContextAddArcToPoint(context, x, y, x + topRadius, y, topRadius);
		CGContextAddArcToPoint(context, x + width, y, x + width, topRadius, topRadius);
		CGContextAddArcToPoint(context, x + width, height + y, x + width - bottomRadius, height + y, bottomRadius);
		CGContextAddArcToPoint(context, x, height + y, x, y + height - bottomRadius, bottomRadius);
		CGContextClosePath(context);
		/*
		 CGPathRef path = CGContextCopyPath(context);
		 
		 CGContextAddPath(context, path);
		 CGContextClip(context);
		 CGPathRelease(path);
		 */
		
		CGContextSetBlendMode(context, kCGBlendModeNormal);
		[backgroundColor setFill];
		CGContextFillPath(context);
	}
}

- (void)setContentOffset:(CGPoint)contentOffset
{
	[super setContentOffset:contentOffset];
	
	/* Force the scrollView to redraw when scrolling (not done since iOS 6, to move the background) */
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

- (void)initialize;

- (void)updateLayout;
- (void)updateScrolling;

@end

@implementation DurationPickerView

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;

@synthesize selectedIndex = _selectedIndex;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self initialize];
	}
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
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
	scrollView = [[_DurationScrollView alloc] initWithFrame:bounds];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:scrollView];
	
	scrollView.delegate = self;
	scrollView.touchDelegate = self;
	
	_DurationMaskView * maskView = [[_DurationMaskView alloc] initWithFrame:self.bounds];
	maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:maskView];
}

- (UIColor *)highlightedTextColor
{
	if (TARGET_IS_IOS7_OR_LATER())
		return [UIColor colorWithWhite:0.1 alpha:1.];
		
	return [UIColor colorWithWhite:0.25 alpha:1.];
}

- (UIColor *)unhighlightedTextColor
{
	if (TARGET_IS_IOS7_OR_LATER())
		return [UIColor lightGrayColor];
	
	return [UIColor grayColor];
}

- (void)reloadData
{
	numberOfItems = [self.dataSource numberOfNumbersInDurationPickerView:self];
	
	const CGFloat labelWidth = 40., labelHeight = 40.;
	
	if (!labels) {
		labels = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
	}
	
	[labels removeAllObjects];
	
	for (int index = 0; index < numberOfItems; index++) {
		NSInteger number = [self.dataSource durationPickerView:self numberForIndex:index];
		
		CGRect rect = CGRectMake(index * labelWidth, 2., labelWidth, labelHeight);
		UILabel * label = [[UILabel alloc] initWithFrame:rect];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = YES;
		label.textColor = (index == _selectedIndex)? [self highlightedTextColor] : [self unhighlightedTextColor];
		
		if (!TARGET_IS_IOS7_OR_LATER()) {
			label.shadowColor = [UIColor colorWithWhite:1. alpha:0.5];
			label.shadowOffset = CGSizeMake(0., 1.);
		}
		label.font = [UIFont boldSystemFontOfSize:17.];
		label.textAlignment = NSTextAlignmentCenter;
		label.text = [NSString stringWithFormat:@"%ld", (long)number];
		[scrollView addSubview:label];
		[labels addObject:label];
	}
	
	[self updateLayout];
}

- (void)updateLayout
{
	const CGFloat labelWidth = 40., labelHeight = 40.;
	scrollView.contentSize = CGSizeMake(numberOfItems * labelWidth, labelHeight);
	int margin = (self.frame.size.width - labelWidth) / 2.;
	scrollView.contentInset = UIEdgeInsetsMake(0., margin, 0., margin);
	
	/* Scroll to correct position (left by default) */
	scrollView.contentOffset = CGPointMake(_selectedIndex * labelWidth - margin, 0.);
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	[self updateLayout];
}


- (void)setSelectedIndex:(NSInteger)selectedIndex
{
	[self selectIndex:selectedIndex animated:NO];
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated
{
	if (0 <= index && index < numberOfItems) {
		UILabel * oldLabel = labels[_selectedIndex];
		oldLabel.textColor = [self unhighlightedTextColor];
		
		UILabel * newLabel = labels[index];
		newLabel.textColor = [self highlightedTextColor];
			
		_selectedIndex = index;
		
		const CGFloat labelWidth = 40.;
		int margin = self.frame.size.width / 2.;
		
		CGFloat newOffset = index * labelWidth - margin + labelWidth / 2.;
		[scrollView setContentOffset:CGPointMake(newOffset, 0.)
							animated:animated];
	}
}


- (void)updateScrolling
{
	const CGFloat labelWidth = 40.;
	int margin = self.frame.size.width / 2.;
	CGFloat offset = scrollView.contentOffset.x + margin;
	
	NSInteger index = offset / labelWidth;
	
	CGFloat newOffset = index * labelWidth - margin + labelWidth / 2.;
	[scrollView setContentOffset:CGPointMake(newOffset, 0.)
						animated:YES];
	
	if (0 <= _selectedIndex && _selectedIndex < labels.count) {
		UILabel * oldLabel = labels[_selectedIndex];
		oldLabel.textColor = [self unhighlightedTextColor];
	}
	
	if (0 <= index && index < labels.count) {
		UILabel * newLabel = labels[index];
		newLabel.textColor = [self highlightedTextColor];
	}
	
	_selectedIndex = index;
	if ([self.delegate respondsToSelector:@selector(durationPickerView:didSelectIndex:)]) {
		[self.delegate durationPickerView:self didSelectIndex:index];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	[self updateScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		[self updateScrolling];
	}
}

- (void)durationScrollView:(_DurationScrollView *)durationScrollView didTouchOnIndex:(NSInteger)index
{
	[self selectIndex:index animated:YES];
	if ([self.delegate respondsToSelector:@selector(durationPickerView:didSelectIndex:)]) {
		[self.delegate durationPickerView:self didSelectIndex:index];
	}
}

@end
