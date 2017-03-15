//
//  MainViewController.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MainViewController_Phone.h"
#import "EditAllCountdownViewController.h"

#import "NetworkStatus.h"

#import "UIView+addition.h"
#import "Countdown+addition.h"

@interface ShadowDropView : UIView
@end

@implementation ShadowDropView

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(CGRect)rect
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
														(__bridge CFArrayRef)@[ (id)[UIColor colorWithWhite:0 alpha:0.05].CGColor,
																				(id)[UIColor clearColor].CGColor ],
														(const CGFloat[]){ 1, 0 });
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}

@end


@interface MainViewController_Phone ()
{
	BOOL _shouldCreateNewCountdown;
}

@property (nonatomic, strong) IBOutlet UIImageView * imageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * leftImageViewConstraint;
@property (nonatomic, strong) IBOutlet UIView * toolbarView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * leftBottomBarConstraint;
@property (nonatomic, strong) UILabel * createCountdownLabel;

- (IBAction)changeCurrentDurationAction:(id)sender;

@end

@implementation MainViewController_Phone

const NSTimeInterval kAnimationDuration = 0.5;
const NSTimeInterval kAnimationDelay = 5.;

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.pages = [[NSMutableArray alloc] initWithCapacity:3];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_imageView.image = [UIImage imageNamed:@"Background"];
	
	_scrollView.pagingEnabled = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.alwaysBounceHorizontal = YES;
	_scrollView.delegate = self;
	_scrollView.clipsToBounds = YES;
	_scrollView.delaysContentTouches = NO;
	
	_pageControl.currentPage = _currentPageIndex;
	
	_createCountdownLabel = [[UILabel alloc] init];
	_createCountdownLabel.textColor = [UIColor whiteColor];
	_createCountdownLabel.text = @"+";
	_createCountdownLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightUltraLight];
	[_createCountdownLabel sizeToFit];
	
	_createCountdownLabel.origin = CGPointMake(15, (self.view.frame.size.height - _createCountdownLabel.frame.size.height) / 2.);
	_createCountdownLabel.alpha = 0;
	[self.view insertSubview:_createCountdownLabel atIndex:0];
	
	if ([_nameLabel respondsToSelector:@selector(adjustsFontForContentSizeCategory)]) // iOS 10+
		_nameLabel.adjustsFontForContentSizeCategory = YES;
	
	_nameLabel.userInteractionEnabled = YES;
	UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
																									action:@selector(changeCurrentDurationAction:)];
	longPressGesture.minimumPressDuration = 0.25;
	[_nameLabel addGestureRecognizer:longPressGesture];
	
	UIGestureRecognizer * tapPressGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
																					action:@selector(showIncentiveAnimationForLongPressAction:)];
	[tapPressGesture requireGestureRecognizerToFail:longPressGesture];
	[_nameLabel addGestureRecognizer:tapPressGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
												 name:CountdownDidSynchronizeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI)
												 name:CountdownDidUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI)
												 name:UIContentSizeCategoryDidChangeNotification object:nil];
	
	[self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (self.pages.count > 0) {
		[self reload];
	} else { // If no coutdowns to show (if the last coutdown has been deleted from delete button)
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		[self presentViewController:navigationController animated:NO completion:NULL];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:CountdownDidSynchronizeNotification];
	[[NSNotificationCenter defaultCenter] removeObserver:CountdownDidUpdateNotification];
	[[NSNotificationCenter defaultCenter] removeObserver:UIContentSizeCategoryDidChangeNotification];
}

#pragma mark - Update content

- (void)reload
{
	if (!_scrollView)
		return ;
	
	@synchronized(self) {
		NSInteger pagesCount = self.pages.count;
		NSInteger countdownsCount = [Countdown allCountdowns].count;
		if (countdownsCount > 0) {
			CLSLog(@"Reload with %ld countdowns and %ld pages", (long)countdownsCount, (long)pagesCount);
			if (pagesCount > countdownsCount) {
				
				// Compute the range of page to remove
				NSRange range = NSMakeRange(countdownsCount, pagesCount - countdownsCount);
				NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
				NSArray * pagesToRemove = [_pages objectsAtIndexes:indexSet];
				
				// Remove pages from superview
				for (PageView * page in pagesToRemove)
					[page removeFromSuperview];
				
				// Remove pages on array
				[_pages removeObjectsInRange:range];
				
			} else if (pagesCount < countdownsCount) {
				
				for (NSUInteger index = pagesCount; index < countdownsCount; ++index) {
					// Just add page on pages array
					Countdown * countdown = [Countdown countdownAtIndex:index];
					[self insertPageWithCountDown:countdown atIndex:index];
				}
			}
		}
		// Reload pages
		int index = 0;
		for (Countdown * countdown in [Countdown allCountdowns].copy) {
			PageView * page = _pages[index];
			
			/* If the type of page needs to change, remove the current page and re-create one */
			if ((countdown.type == CountdownTypeTimer && [page isKindOfClass:CountdownPageView.class]) ||
				(countdown.type == CountdownTypeCountdown && [page isKindOfClass:TimerPageView.class])) {
				[self removePageAtIndex:index];
				[self insertPageWithCountDown:countdown atIndex:index];
			}
			page.frame = CGRectMake(index * self.view.frame.size.width, 0.,
									self.view.frame.size.width, self.view.frame.size.height);
			page.countdown = countdown;
			index++;
		}
		
		_scrollView.contentSize = CGSizeMake(self.view.frame.size.width * _pages.count, 0.);
		CGPoint contentOffset = CGPointMake(self.view.frame.size.width * _currentPageIndex, 0.);
		[_scrollView setContentOffset:contentOffset animated:NO];
		
		[self showPageControl:NO animated:NO];
		if (_pages.count) {
			_pageControl.numberOfPages = _pages.count;
			[self updateBarContentWithOffset:_scrollView.contentOffset];
			[self setCurrentPageIndex:_currentPageIndex];
		} else
			_nameLabel.text = nil;
	}
}

- (void)updateContentView
{
	// Re-order pages
	int index = 0;
	for (PageView * page in _pages) {
		CGFloat y = (self.view.frame.size.height - 423./*background image height*/) / 2.;
		page.frame = CGRectMake(index * self.view.frame.size.width, (int)y,
								self.view.frame.size.width, self.view.frame.size.height);
		++index;
	}
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _pages.count, 0.);
	
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _currentPageIndex, 0.);
	[_scrollView setContentOffset:contentOffset animated:NO];
}

- (void)updateUI
{
	if (0 <= _currentPageIndex && _currentPageIndex < _pages.count) {
		[self setBackgroundImageOffset:CGPointZero];
		[self updateName];
		[self updateLeftButton];
	}
}

- (void)updateName
{
	PageView * currentPage = _pages[_currentPageIndex];
	UIColor * textColor = [UIColor textColorForStyle:currentPage.countdown.style];
	_nameLabel.textColor = textColor;
	_nameLabel.attributedText = currentPage.countdown.attributedName;
	[_nameLabel invalidateIntrinsicContentSize];
}

- (void)updateLeftButton
{
	PageView * pageView = _pages[_currentPageIndex];
	if (pageView.countdown.type == CountdownTypeTimer) {
		NSString * name = (pageView.countdown.isPaused) ? @"reset" : @"pause";
		[_leftButton setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
		_leftButton.enabled = (pageView.countdown.durations.count > 0);
	}
}

#pragma mark - Page management

- (void)addPageWithCountDown:(Countdown *)aCountdown
{
	[self insertPageWithCountDown:aCountdown atIndex:_pages.count];
}

- (void)insertPageWithCountDown:(Countdown *)aCountdown atIndex:(NSInteger)index
{
	const Class class = (aCountdown.type == CountdownTypeTimer) ? TimerPageView.class : CountdownPageView.class;
	const CGRect frame = CGRectMake(index * self.view.frame.size.width, 0., self.view.frame.size.width,
									self.view.frame.size.height - _toolbarView.frame.size.height);
	PageView * page = [[class alloc] initWithFrame:frame];
	page.delegate = self;
	page.countdown = aCountdown;
	[_pages insertObject:page atIndex:index];
	
	[self.scrollView addSubview:page];
}

- (void)removePageWithCountdown:(Countdown *)aCountdown
{
	NSInteger index = [Countdown indexOfCountdown:aCountdown];
	if (index != NSNotFound) {
		[self removePageAtIndex:index];
	}
}

- (void)removePageAtIndex:(NSInteger)index
{
	PageView * pageView = _pages[index];
	[pageView viewDidHide:NO];
	[pageView removeFromSuperview];
	[_pages removeObjectAtIndex:index];
}

- (void)removeAllPages
{
	for (PageView * page in _pages) {
		[page viewDidHide:NO];
		[page removeFromSuperview];
	}
	[_pages removeAllObjects];
}

- (void)setCurrentPageIndex:(NSInteger)pageIndex
{
	_pageControl.currentPage = pageIndex;
	_currentPageIndex = pageIndex;
	[self updateUI];
}

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (0 <= pageIndex && pageIndex < [Countdown allCountdowns].count) {
		self.currentPageIndex = pageIndex;
		[self reload];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateUI];
			PageView * page = _pages[pageIndex];
			[page viewWillShow:animated];
		});
	}
}

- (void)selectPageWithCountdown:(Countdown *)countdown animated:(BOOL)animated
{
	NSUInteger index = [[_pages valueForKey:NSStringFromSelector(@selector(countdown))] indexOfObject:countdown];
	if (index != NSNotFound)
		[self showPageAtIndex:index animated:animated];
}

#pragma mark - Update time labels

- (void)startUpdateTimeLabels
{
	[_updateTimeLabelTimer invalidate];
	self.updateTimeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updateTimeLabels)
															   userInfo:nil repeats:YES];
	[self updateTimeLabels];
}

- (void)updateTimeLabels
{
	int index = 0;
	for (PageView * page in _pages) {
		if (ABS(_currentPageIndex - index) <= 1) { // Update only the current page and it left and right neighbours
			dispatch_async(dispatch_get_main_queue(), ^{ [page update]; });
		}
		++index;
	}
}

- (void)stopUpdateTimeLabels
{
	[_updateTimeLabelTimer invalidate];
	self.updateTimeLabelTimer = nil;
}

#pragma mark - Settings view controller delegate

- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller
{
	[self reload];
	[self updateContentView];
	
	if ([Countdown allCountdowns].count > 0) {
		NSInteger pageIndex = [Countdown indexOfCountdown:controller.countdown];
		if (pageIndex == NSNotFound)
			pageIndex = _pages.count - 1;// Select the last countdown
		
		self.currentPageIndex = pageIndex;
		CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * pageIndex, 0.);
		[_scrollView setContentOffset:contentOffset animated:NO];
		[_pages[pageIndex] viewWillShow:YES];
		
		[self startUpdateTimeLabels];
		[self dismissViewControllerAnimated:YES completion:NULL];
		
	} else {
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		
		[self dismissViewControllerAnimated:NO completion:NULL];
		[self presentViewController:navigationController animated:NO completion:NULL];
	}
}

#pragma mark - PageView delegate

- (void)pageViewDidDoubleTap:(PageView *)page
{
	NSInteger index = [_pages indexOfObject:page];
	if (index == NSNotFound)
		index = _currentPageIndex;
	
	[self showSettingsForPageAtIndex:index animated:YES];
}

#pragma mark - Actions

- (IBAction)leftButtonAction:(id)sender
{
	TimerPageView * page = (TimerPageView *)_pages[_currentPageIndex];
	if ([page isKindOfClass:TimerPageView.class]) {
		if (page.countdown.isPaused) { // Reset
			[page reset];
		} else {
			[page tooglePause];
		}
		[self updateLeftButton];
	}
}

- (IBAction)showSettings:(id)sender
{
	[self showSettingsForPageAtIndex:_currentPageIndex animated:YES];
}

- (BOOL)allowsDurationPickupForCurrentPage
{
	TimerPageView * page = (TimerPageView *)_pages[_currentPageIndex];
	Countdown * timer = page.countdown;
	return ([page isKindOfClass:TimerPageView.class] &&
			timer.type == CountdownTypeTimer && timer.durations.count > 1);
}

- (IBAction)showIncentiveAnimationForLongPressAction:(UIGestureRecognizer *)sender
{
	if (self.allowsDurationPickupForCurrentPage) {
		[UIView animateWithDuration:0.15 animations:^{
			self.view.transform = CGAffineTransformMakeScale(0.92, 0.92);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.25 initialSpringVelocity:1 options:0 animations:^{
				self.view.transform = CGAffineTransformIdentity;
			} completion:nil];
		}];
	}
}

- (IBAction)changeCurrentDurationAction:(UIGestureRecognizer *)sender // @FIXME: This is called 2 times on long press
{
	if (self.allowsDurationPickupForCurrentPage && sender.state != UITouchPhaseCancelled) {
		TimerPageView * page = (TimerPageView *)_pages[_currentPageIndex];
		Countdown * timer = page.countdown;
		NSString * title = NSLocalizedString(@"Choose current duration", nil);
		UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:title message:nil
																	   preferredStyle:UIAlertControllerStyleActionSheet];
		for (NSInteger index = 0; index < timer.durations.count; ++index) {
			NSMutableString * title = [timer shortDescriptionOfDurationAtIndex:index].mutableCopy;
			NSString * name = timer.names[index];
			if (name.length > 0)
				[title insertString:[NSString stringWithFormat:@"%@ - ", name] atIndex:0];
			if (index == timer.durationIndex ?: 0)
				title = [NSString stringWithFormat:@"✓ %@	", title].mutableCopy;
			
			UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
				timer.durationIndex = index;
				[timer reset]; [page reset];
				[self updateUI];
			}];
			action.enabled = (index != timer.durationIndex ?: 0);
			[actionSheet addAction:action];
		}
		[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
														style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:actionSheet animated:YES completion:nil];
	}
}

#pragma mark - Go to settings

- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (pageIndex < [Countdown allCountdowns].count) {
		if (!_settingsViewController) {
			_settingsViewController = [[SettingsViewController alloc] init];
			_settingsViewController.delegate = self;
		}
		
		Countdown * currentCountdown = (Countdown *)[Countdown allCountdowns][_currentPageIndex];
		_settingsViewController.countdown = currentCountdown;
		
		UINavigationController * aNavigationController = [[UINavigationController alloc] initWithRootViewController:_settingsViewController];
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:aNavigationController animated:YES completion:^{
			[_pages[pageIndex] viewDidHide:animated]; }];
		
		[self stopUpdateTimeLabels];
	}
}

#pragma mark - Scroll view delegate

- (void)setBackgroundImageOffset:(CGPoint)point
{
	_leftImageViewConstraint.constant = point.x;
	
	CGFloat x = 15;
	if (point.x < 0)
		x = self.view.frame.size.width - _createCountdownLabel.frame.size.width - 15;
	
	_createCountdownLabel.origin = CGPointMake(x, (self.view.frame.size.height - _createCountdownLabel.frame.size.height) / 2.);
	_shouldCreateNewCountdown = (ABS(point.x) > 70);
	_createCountdownLabel.alpha = (_shouldCreateNewCountdown) ? 1 : ((ABS(point.x) - 30) / 70);
	
	_leftBottomBarConstraint.constant = point.x;
}

- (void)showPageControl:(BOOL)show animated:(BOOL)animated
{
	if (animated) {
		NSTimeInterval duration = 0.15;
		[UIView animateWithDuration:duration animations:^{
			if (show) _nameLabel.alpha = 0;
			else _pageControl.alpha = 0;
		}];
		[UIView animateWithDuration:duration delay:duration / 2. options:0 animations:^{
			if (show) _pageControl.alpha = 1;
			else _nameLabel.alpha = 1;
		} completion:^(BOOL finished) { }];
	} else {
		_nameLabel.alpha = (!show);
		_pageControl.alpha = (show);
	}
}

- (void)updateBarContentWithOffset:(CGPoint)offset
{
	NSInteger index = floor(offset.x / _scrollView.frame.size.width);
	CGFloat progression = (offset.x / _scrollView.frame.size.width) - index;
	PageView * leftPageView = _pages[MAX(0, index)];
	PageView * rightPageView = _pages[MIN(index+1, _pages.count-1)];
	const CountdownStyle * styles = (const CountdownStyle[]){ leftPageView.style, rightPageView.style };
	UIColor * tintColor = [UIColor textColorForStyles:styles indexValue:progression];
	
	_pageControl.currentPageIndicatorTintColor = tintColor;
	_pageControl.pageIndicatorTintColor = [tintColor colorWithAlphaComponent:0.333];
	
	_infoButton.tintColor = tintColor;
	_leftButton.tintColor = tintColor;
	
	UIColor * backgroundColor = [UIColor backgroundColorForStyles:styles indexValue:progression];
	if (UIAccessibilityIsReduceTransparencyEnabled()) {
		_nameLabel.superview.backgroundColor = [backgroundColor colorWithAlphaComponent:0.65];
		_toolbarView.backgroundColor = nil;
	} else {
		_toolbarView.backgroundColor = [backgroundColor colorWithAlphaComponent:0.25];
		_nameLabel.superview.backgroundColor = nil;
	}
	
	CGFloat a = (leftPageView.countdown.type == CountdownTypeTimer) ? 1 : progression;
	CGFloat b = (rightPageView.countdown.type == CountdownTypeTimer) ? 0 : progression;
#define SMOOTH(X) ({ __typeof__(X) T = (X); T*T*T*(T*(T*6.-15.)+10.); })
	_leftButton.alpha = SMOOTH(a-b);
#undef SMOOTH
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	dispatch_async(dispatch_get_main_queue(), ^{
		BOOL shouldShowControls = (scrollView.contentOffset.x >= 0 &&
								   scrollView.contentOffset.x <= scrollView.contentSize.width - scrollView.frame.size.width);
		[self showPageControl:shouldShowControls animated:NO];
	});
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	CGFloat offset = _scrollView.contentOffset.x / _scrollView.frame.size.width;
	NSInteger index = MAX(roundf(offset), 0);
	self.currentPageIndex = index;
	
	if (0 <= index && index < _pages.count) {
		PageView * pageView = _pages[index];
		if (pageView) {
			if (_scrollView.contentOffset.x < 0.) {
				CGFloat offset = -_scrollView.contentOffset.x;
				[self setBackgroundImageOffset:CGPointMake(offset, 0.)];
				
			} else if (_scrollView.contentOffset.x > (_scrollView.frame.size.width * (_pageControl.numberOfPages - 1))) {
				CGFloat offset = (_scrollView.frame.size.width * (_pageControl.numberOfPages - 1)) - _scrollView.contentOffset.x;
				[self setBackgroundImageOffset:CGPointMake(offset, 0.)];
			}
			[self setNeedsStatusBarAppearanceUpdate];
		}
		[self updateBarContentWithOffset:_scrollView.contentOffset];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)aScrollView
{
	NSInteger pageIndex = floor(_scrollView.contentOffset.x / _scrollView.frame.size.width);
	int index = 0;
	for (PageView * page in _pages) {
		if (ABS(pageIndex - index) <= 1) // Update only the current page and it left and right neighbours
			[page update];
		++index;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	PageView * pageView = _pages[_currentPageIndex];
	if (!pageView.isViewShown) [pageView viewWillShow:YES];
	for (PageView * aPageView in _pages) {
		if (aPageView != pageView && aPageView.isViewShown)
			[aPageView viewDidHide:YES];
	}
	[self showPageControl:NO animated:YES];
	[self updateUI];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		PageView * pageView = _pages[_currentPageIndex];
		if (!pageView.isViewShown) [pageView viewWillShow:YES];
		for (PageView * aPageView in _pages) {
			if (aPageView != pageView && aPageView.isViewShown)
				[aPageView viewDidHide:YES];
		}
		[self setBackgroundImageOffset:CGPointZero];
		
	} else if (_shouldCreateNewCountdown) {
		Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.name = NSLocalizedString(@"New Countdown", nil);
		[Countdown addCountdown:countdown];
		[Answers logCustomEventWithName:@"use-quick-create-countdown" customAttributes:nil];
		[self reload];
		
		NSInteger index = [Countdown indexOfCountdown:countdown];
		dispatch_async(dispatch_get_main_queue(), ^{
			PageView * page = _pages[index];
			page.transform = _imageView.transform = CGAffineTransformMakeScale(0.5, 0.5);
			page.alpha = _imageView.alpha = 0.;
			[UIView animateWithDuration:0.25 animations:^{
				page.transform = _imageView.transform = CGAffineTransformIdentity;
				page.alpha = _imageView.alpha = 1.;
			}
							 completion:^(BOOL finished) {
								 [self showSettingsForPageAtIndex:index animated:YES];
							 }];
		});
		
		scrollView.contentOffset = CGPointMake(index * scrollView.frame.size.width, 0);
		self.currentPageIndex = index;
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	if (_pages.count) {
		PageView * pageView = _pages[_currentPageIndex];
		return CountdownStyleHasDarkContent(pageView.style) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
	}
	return UIStatusBarStyleDefault;
}

#pragma mark - Page control managment

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _currentPageIndex, 0.);
	[_scrollView setContentOffset:contentOffset animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self updateContentView];
}

@end
