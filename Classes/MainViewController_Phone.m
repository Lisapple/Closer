//
//  MainViewController.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MainViewController_Phone.h"
#import "EditAllCountdownViewController.h"

#import "Countdown.h"
#import "NetworkStatus.h"

#import "UIView+addition.h"

#import <Crashlytics/Crashlytics.h>

@interface MainViewController_Phone ()
{
	BOOL _shouldCreateNewCountdown;
}

@property (nonatomic, strong) IBOutlet UIImageView * imageView;
@property (nonatomic, strong) UILabel * createCountdownLabel;

@end

@implementation MainViewController_Phone

const NSTimeInterval kAnimationDuration = 0.5;
const NSTimeInterval kAnimationDelay = 5.;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.pages = [[NSMutableArray alloc] initWithCapacity:3];
	
	_imageView.image = [UIImage imageNamed:@"Background"];
	
	_scrollView.pagingEnabled = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.alwaysBounceHorizontal = YES;
	_scrollView.delegate = self;
    _scrollView.clipsToBounds = YES;
	_scrollView.delaysContentTouches = NO;
	
	_pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight; // Add flexible height (Unavailable from IB)
	
	_createCountdownLabel = [[UILabel alloc] init];
	_createCountdownLabel.textColor = [UIColor whiteColor];
	_createCountdownLabel.text = @"+";
	_createCountdownLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightUltraLight];
	[_createCountdownLabel sizeToFit];
	
	_createCountdownLabel.origin = CGPointMake(15, (self.view.frame.size.height - _createCountdownLabel.frame.size.height) / 2.);
	_createCountdownLabel.alpha = 0;
	
	[self.view insertSubview:_createCountdownLabel atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
												 name:CountdownDidSynchronizeNotification object:nil];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:CountdownDidSynchronizeNotification];
}

#pragma mark - Current page index

- (NSInteger)selectedPageIndex
{
	return _pageControl.currentPage;
}

#pragma mark - Add page

- (void)addPageWithCountDown:(Countdown *)aCountdown
{
	[self insertPageWithCountDown:aCountdown atIndex:_pages.count];
}

- (void)insertPageWithCountDown:(Countdown *)aCountdown atIndex:(NSInteger)index
{
	CGRect frame = CGRectMake(index * _scrollView.frame.size.width, 0.,
							  _scrollView.frame.size.width, _scrollView.frame.size.height);
	PageView * page = nil;
	if (aCountdown.type == CountdownTypeTimer)
		page = [[TimerPageView alloc] initWithFrame:frame];
	else
		page = [[CountdownPageView alloc] initWithFrame:frame];
	
	page.delegate = self;
	page.countdown = aCountdown;
	[_pages insertObject:page atIndex:index];
	
	[self.scrollView addSubview:page];
	
	[self.view bringSubviewToFront:_pageControl];
}

- (void)update
{
	[self reload];
}

- (void)reload
{
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
			
			for (int i = 0; i < (countdownsCount - pagesCount); i++) {
				// Just add page on pages array
				Countdown * countdown = [Countdown countdownAtIndex:i];
				[self addPageWithCountDown:countdown];
			}
		}
	}
	
	// Reload pages
	int index = 0;
	for (Countdown * countdown in [Countdown allCountdowns]) {
		PageView * page = _pages[index];
		
		/* If the type of page needs to change, remove the current page and re-create one */
		if ((countdown.type == CountdownTypeTimer && [page isKindOfClass:CountdownPageView.class]) ||
			(countdown.type == CountdownTypeCountdown && [page isKindOfClass:TimerPageView.class])) {
			[self removePageAtIndex:index];
			[self insertPageWithCountDown:countdown atIndex:index];
		}
		
		page.frame = CGRectMake(index * _scrollView.frame.size.width, 0.,
								_scrollView.frame.size.width, _scrollView.frame.size.height);
		page.countdown = countdown;
		index++;
	}
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _pages.count, 0.);
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _pageControl.currentPage, 0.);
	[_scrollView setContentOffset:contentOffset animated:NO];
	
	if (_pages.count) {
		_pageControl.numberOfPages = _pages.count;
		PageView * pageView = _pages[_pageControl.currentPage];
		UIColor * textColor = [UIColor textColorForStyle:pageView.style];
		_pageControl.currentPageIndicatorTintColor = textColor;
		_pageControl.pageIndicatorTintColor = [textColor colorWithAlphaComponent:0.5];
	}
}

- (void)updateContentView
{
	// Re-order pages
	int index = 0;
	for (PageView * page in _pages) {
		CGFloat y = (_scrollView.frame.size.height - 423.) / 2.; // The height of the background image of the pageView is 423pt
		page.frame = CGRectMake(index * _scrollView.frame.size.width, (int)y, _scrollView.frame.size.width, _scrollView.frame.size.height);
		++index;
	}
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _pages.count, 0.);
	
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _pageControl.currentPage, 0.);
	[_scrollView setContentOffset:contentOffset animated:NO];
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

#pragma mark - Pages and settings selection

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (pageIndex < [Countdown allCountdowns].count) {
		
		_pageControl.currentPage = pageIndex;
		CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * pageIndex, 0.);
		[_scrollView setContentOffset:contentOffset animated:animated];
		[_pages[pageIndex] viewWillShow:animated];
	}
}

- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (pageIndex < [Countdown allCountdowns].count) {
		
		[UIApplication sharedApplication].statusBarHidden = NO; // @TODO: Remove if unused
		
		if (!_settingsViewController) {
			_settingsViewController = [[SettingsViewController_Phone alloc] init];
			_settingsViewController.delegate = self;
		}
		
		Countdown * currentCountdown = (Countdown *)[Countdown allCountdowns][_pageControl.currentPage];
		_settingsViewController.countdown = currentCountdown;
		
		UINavigationController * aNavigationController = [[UINavigationController alloc] initWithRootViewController:_settingsViewController];
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:aNavigationController animated:YES completion:^{
			[_pages[pageIndex] viewDidHide:animated]; }];
		
		[self stopUpdateTimeLabels];
	}
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
		if (ABS(_pageControl.currentPage - index) <= 1) {// Update only the current page and it left and right neighbours
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

- (void)settingsViewControllerDidFinish:(SettingsViewController_Phone *)controller
{
	[self reload];
	[self updateContentView];
	
	if ([Countdown allCountdowns].count > 0) {
		NSInteger pageIndex = [Countdown indexOfCountdown:controller.countdown];
		if (pageIndex == NSNotFound)
			pageIndex = _pages.count - 1;// Select the last countdown
		
		_pageControl.currentPage = pageIndex;
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

#pragma mark - Go to settings

- (void)pageViewWillShowSettings:(PageView *)page
{
	NSInteger index = [_pages indexOfObject:page];
	if (index == NSNotFound)
		index = _pageControl.currentPage;
	
	[self showSettingsForPageAtIndex:index animated:YES];
}

- (IBAction)showSettings:(id)sender
{
	[self showSettingsForPageAtIndex:_pageControl.currentPage animated:YES];
}

- (void)pageViewWillShowDeleteConfirmation:(PageView *)page
{
	[UIView animateWithDuration:0.1
					 animations:^{ _pageControl.alpha = 0.; }
					 completion:^(BOOL finished) { _pageControl.hidden = YES; }];
}

- (void)pageViewDidScroll:(PageView *)page offset:(CGPoint)offset
{
	[self setBackgroundImageOffset:offset];
}

- (void)pageViewDidHideDeleteConfirmation:(PageView *)page
{
	_pageControl.hidden = NO;
	[UIView animateWithDuration:0.1
					 animations:^{ _pageControl.alpha = 1.; }
					 completion:^(BOOL finished) { _scrollView.scrollEnabled = YES; }];
}

- (void)pageViewDeleteButtonDidTap:(PageView *)page
{
	[page hideDeleteConfirmationWithAnimation:NO];
	[UIView animateWithDuration:0.3
					 animations:^{
						 CGRect frame = page.frame;
						 frame.origin.y -= [UIScreen mainScreen].bounds.size.height;
						 page.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 /* Get the countdown next this one */
						 Countdown * countdown = [Countdown countdownAtIndex:(_pageControl.currentPage)];
						 [Countdown removeCountdown:countdown];
						 
						 NSInteger count = [Countdown allCountdowns].count;
						 if (count == 0) { // If we have deleted the last countdown, show editAllCountdowns: panel
							 EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
							 UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
							 [self presentViewController:navigationController animated:YES completion:NULL];
						 }
						 [self setNeedsStatusBarAppearanceUpdate];
						 
						 [self reload];
					 }];
}

#pragma mark - Scroll view delegate

- (void)setBackgroundImageOffset:(CGPoint)point
{
	_imageView.origin = point;
	
	CGFloat x = 15;
	if (point.x < 0) {
		x = self.view.frame.size.width - _createCountdownLabel.frame.size.width - 15;
	}
	_createCountdownLabel.origin = CGPointMake(x, (self.view.frame.size.height - _createCountdownLabel.frame.size.height) / 2.);
	_createCountdownLabel.alpha = (ABS(point.x) > 40) ? 1 : ((ABS(point.x) - 20) / 40);
	
	_shouldCreateNewCountdown = (ABS(point.x) > 40);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	CGFloat offset = _scrollView.contentOffset.x / _scrollView.frame.size.width;
	NSInteger index = MAX(roundf(offset), 0);
	_pageControl.currentPage = index;
	
	if (0 <= index && index < _pages.count) {
		
		PageView * pageView = _pages[index];
		if (pageView.showDeleteConfirmation) {
			_scrollView.scrollEnabled = NO;
			[pageView hideDeleteConfirmation];
			
		} else if (pageView) {
			UIColor * textColor = [UIColor textColorForStyle:pageView.style];
			_pageControl.currentPageIndicatorTintColor = textColor;
			_pageControl.pageIndicatorTintColor = [textColor colorWithAlphaComponent:0.5];
			
			if (_scrollView.contentOffset.x < 0.) {
				CGFloat offset = -_scrollView.contentOffset.x;
				[self setBackgroundImageOffset:CGPointMake(offset, 0.)];
				
			} else if (_scrollView.contentOffset.x > (_scrollView.frame.size.width * (_pageControl.numberOfPages - 1))) {
				CGFloat offset = (_scrollView.frame.size.width * (_pageControl.numberOfPages - 1)) - _scrollView.contentOffset.x;
				[self setBackgroundImageOffset:CGPointMake(offset, 0.)];
			}
			[self setNeedsStatusBarAppearanceUpdate];
		}
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
	PageView * pageView = _pages[_pageControl.currentPage];
	if (!pageView.isViewShown) [pageView viewWillShow:YES];
	for (PageView * aPageView in _pages) {
		if (aPageView != pageView && aPageView.isViewShown) {
			[aPageView viewDidHide:YES];
		}
	}
	[self setBackgroundImageOffset:CGPointZero];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		PageView * pageView = _pages[_pageControl.currentPage];
		if (!pageView.isViewShown) [pageView viewWillShow:YES];
		for (PageView * aPageView in _pages) {
			if (aPageView != pageView && aPageView.isViewShown) {
				[aPageView viewDidHide:YES];
			}
		}
		[self setBackgroundImageOffset:CGPointZero];
		
	} else if (_shouldCreateNewCountdown) {
		Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.name = NSLocalizedString(@"New Countdown", nil);
		[Countdown addCountdown:countdown];
		[self reload];
		
		NSInteger index = [Countdown indexOfCountdown:countdown];
		scrollView.contentOffset = CGPointMake(index * scrollView.frame.size.width, 0);
		_pageControl.currentPage = index;
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self showSettingsForPageAtIndex:index animated:YES];
		});
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	if (_pages.count) {
		PageView * pageView = _pages[_pageControl.currentPage];
		return (pageView.style == CountdownStyleDay || pageView.style == CountdownStyleSpring) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
	}
	return UIStatusBarStyleDefault;
}

#pragma mark - Page control managment

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _pageControl.currentPage, 0.);
	[_scrollView setContentOffset:contentOffset animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self updateContentView];
}

@end
