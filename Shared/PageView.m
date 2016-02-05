//
//  PageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "PageView.h"

#import "NSObject+additions.h"

@interface _DeleteButton ()

@property (nonatomic, strong) UILabel * label;

@end

@implementation _DeleteButton

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		_label = [[UILabel alloc] initWithFrame:self.bounds];
		_label.textColor = [UIColor whiteColor];
		_label.backgroundColor = [UIColor clearColor];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.font = [UIFont systemFontOfSize:20.];
		[self addSubview:_label];
		
		_label.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
		
		self.clipsToBounds = YES;
	}
	return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
	_label.text = title;
}

@end


@interface PageView ()

@property (nonatomic, strong) UIButton * deleteButton;

@property (nonatomic, assign) CGPoint startLocation, offset;
@property (nonatomic, assign) BOOL shouldShowDeleteConfirmation;

@property (nonatomic, strong) UIScrollView * scrollView;

@end

@implementation PageView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		_shouldShowDeleteConfirmation = YES;
		
		CGRect rect = CGRectMake(0., frame.size.height - 60., frame.size.width, 60.);
		_deleteButton = [[_DeleteButton alloc] initWithFrame:rect];
		_deleteButton.backgroundColor = [UIColor redColor];
		[_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
		[self addSubview:_deleteButton];
		[_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
		_deleteButton.frame = CGRectMake(0., frame.size.height, frame.size.width, 0.);
		_deleteButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		
		_scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
		_scrollView.delegate = self;
		_scrollView.delaysContentTouches = NO;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.alwaysBounceVertical = YES;
		_scrollView.contentSize = CGSizeMake(0., frame.size.height + 60.);
		_scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self addSubview:_scrollView];
		
		UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
		gesture.numberOfTapsRequired = 2;
		[_scrollView addGestureRecognizer:gesture];
	}
	return self;
}

- (void)setFrame:(CGRect)frame
{
	super.frame = frame;
	
	_deleteButton.frame = CGRectMake(0., self.frame.size.height, self.frame.size.width, 0.);
	_scrollView.contentSize = CGSizeMake(0., frame.size.height + 60.);
}

- (void)update
{
	/* Subsclasses must implement it */
}

- (void)viewWillShow:(BOOL)animated
{
	_isViewShown = YES;
}

- (void)viewDidHide:(BOOL)animated
{
	_isViewShown = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Hide the delete button on tap (outside the delete button)
	if (_showDeleteConfirmation)
		[self hideDeleteConfirmation];
}

- (void)handleDoubleTap
{
    [_infoButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)hideDeleteConfirmation
{
	[self hideDeleteConfirmationWithAnimation:YES];
}

- (void)hideDeleteConfirmationWithAnimation:(BOOL)animated
{
	self.userInteractionEnabled = NO;
	[_scrollView setContentOffset:CGPointZero animated:animated];
	[NSObject performBlock:^{ self.userInteractionEnabled = YES; }
				afterDelay:(animated) ? 0.2 : 0.];
	
}

- (void)deleteAction:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(pageViewDeleteButtonDidTap:)]) {
		if (([self.delegate respondsToSelector:@selector(pageViewShouldBeDeleted:)] &&
			[self.delegate pageViewShouldBeDeleted:self]) ||
			![self.delegate respondsToSelector:@selector(pageViewShouldBeDeleted:)]) {
			[self.delegate pageViewDeleteButtonDidTap:self];
		}
	}
}

- (void)setShowDeleteConfirmation:(BOOL)showDeleteConfirmation
{
	_showDeleteConfirmation = showDeleteConfirmation;
	
	// Disable user interaction for |_scrollView| when the delete button is showing
	_scrollView.userInteractionEnabled = !showDeleteConfirmation;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if ([self.delegate respondsToSelector:@selector(pageViewShouldShowDeleteConfirmation:)])
		_shouldShowDeleteConfirmation = [self.delegate pageViewShouldShowDeleteConfirmation:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (!_shouldShowDeleteConfirmation) {
		scrollView.contentOffset = CGPointZero;
		return ;
	}
	
	/**/ if (scrollView.contentOffset.y < 0.)
		self.scrollView.contentOffset = CGPointZero;
	else if (scrollView.contentOffset.y >= 60.)
		self.scrollView.contentOffset = CGPointMake(0., 60.);
	else if (scrollView.contentOffset.y == 0.) {
		self.showDeleteConfirmation = NO;
		if ([self.delegate respondsToSelector:@selector(pageViewDidHideDeleteConfirmation:)])
			[self.delegate pageViewDidHideDeleteConfirmation:self];
	}
	else if (!_showDeleteConfirmation) {
		self.showDeleteConfirmation = YES;
		if ([self.delegate respondsToSelector:@selector(pageViewWillShowDeleteConfirmation:)])
			[self.delegate pageViewWillShowDeleteConfirmation:self];
	}
	
	if ([self.delegate respondsToSelector:@selector(pageViewDidScroll:offset:)])
		[self.delegate pageViewDidScroll:self offset:CGPointMake(_scrollView.contentOffset.x,
																 -_scrollView.contentOffset.y)];
	
	CGFloat height = scrollView.contentOffset.y;
	CGRect frame = _deleteButton.frame;
	frame.size.height = height;
	frame.origin.y = scrollView.frame.size.height - height;
	_deleteButton.frame = frame;
}

- (void)_scrollViewDidEndScrolling:(UIScrollView *)scrollView
{
	CGPoint offset = scrollView.contentOffset;
	
	if (offset.y < 30.)
		[self.scrollView setContentOffset:CGPointZero animated:YES];
	else {
		[self.scrollView setContentOffset:CGPointMake(0., 60.) animated:YES];
		
		[NSObject performBlock:^{
			self.showDeleteConfirmation = YES;
			if ([self.delegate respondsToSelector:@selector(pageViewDidShowDeleteConfirmation:)])
				[self.delegate pageViewDidShowDeleteConfirmation:self];
		}
					afterDelay:0.2];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate)
		[self _scrollViewDidEndScrolling:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self _scrollViewDidEndScrolling:scrollView];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	_startLocation = [((UITouch *)touches.anyObject) locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	_offset = [((UITouch *)touches.anyObject) locationInView:self];
	_offset.x = _startLocation.x; _offset.y = _startLocation.y;
}

@end
