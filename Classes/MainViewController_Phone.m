//
//  MainViewController.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MainViewController_Phone.h"

#import "Countdown.h"

#import "EditAllCountdownViewController.h"

#import "NetworkStatus.h"

@interface MainViewController_Phone ()

@property (nonatomic, strong) IBOutlet UIImageView * imageView;

@end

@implementation MainViewController_Phone

@synthesize scrollView;
@synthesize pageControl;
@synthesize mainView;
@synthesize label;
@synthesize infoButton;

@synthesize updateTimeLabelTimer, animationDelay;

@synthesize pages;

const NSTimeInterval kAnimationDuration = 0.5;
const NSTimeInterval kAnimationDelay = 5.;

#pragma mark -
#pragma mark View Load/Appear/Disappear Managment

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.pages = [[NSMutableArray alloc] initWithCapacity:3];
	
	_imageView.image = [UIImage imageNamed:@"Background"];
	
	scrollView.pagingEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.alwaysBounceHorizontal = YES;
	scrollView.delegate = self;
	
	pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
}

- (void)viewWillAppear:(BOOL)animated
{
	[self reload];
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	if (self.pages.count > 0) {
		[self reload];
	} else { // If no coutdowns to show (if the last coutdown has been deleted from delete button)
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		[self presentViewController:navigationController animated:NO completion:NULL];
	}
	
	[super viewDidAppear:animated];
}

#pragma mark - Current Page Index

- (NSInteger)selectedPageIndex
{
	return pageControl.currentPage;
}

#pragma mark - Add Page

- (void)addPageWithCountDown:(Countdown *)aCountdown
{
	[self insertPageWithCountDown:aCountdown atIndex:pages.count];
}

- (void)insertPageWithCountDown:(Countdown *)aCountdown atIndex:(NSInteger)index
{
	CGRect frame = CGRectMake(index * scrollView.frame.size.width, 0.,
							  scrollView.frame.size.width, scrollView.frame.size.height);
	
	PageView * page = nil;
	if (aCountdown.type == CountdownTypeTimer)
		page = [[TimerPageView alloc] initWithFrame:frame];
	else
		page = [[CountdownPageView alloc] initWithFrame:frame];
	
	page.delegate = self;
	page.countdown = aCountdown;
	[pages insertObject:page atIndex:index];
	
	[self.scrollView addSubview:page];
	
	[self.view bringSubviewToFront:pageControl];
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
		if (pagesCount > countdownsCount) {
			
			// Compute the range of page to remove
			NSRange range = NSMakeRange(countdownsCount, pagesCount - countdownsCount);
			
			NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
			NSArray * pagesToRemove = [pages objectsAtIndexes:indexSet];
			
			// Remove pages from superview
			for (PageView * page in pagesToRemove)
				[page removeFromSuperview];
			
			// Remove pages on array
			[pages removeObjectsInRange:range];
			
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
		PageView * page = pages[index];
		
		/* If the type of page needs to change, remove the current page and re-create one */
		if ((countdown.type == CountdownTypeTimer && [page isKindOfClass:[CountdownPageView class]])
			|| (countdown.type == CountdownTypeCountdown && [page isKindOfClass:[TimerPageView class]])) {
			[self removePageAtIndex:index];
			[self insertPageWithCountDown:countdown atIndex:index];
		}
		
		page.frame = CGRectMake(index * scrollView.frame.size.width, 0.,
								scrollView.frame.size.width, scrollView.frame.size.height);
		page.countdown = countdown;
		index++;
	}
	
	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * pages.count, 0.);
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:NO];
	
	pageControl.numberOfPages = pages.count;
	PageView * pageView = pages[pageControl.currentPage];
	UIColor * textColor = [UIColor textColorForPageStyle:pageView.style];
	pageControl.currentPageIndicatorTintColor = textColor;
	pageControl.pageIndicatorTintColor = [textColor colorWithAlphaComponent:0.5];
}

- (void)updateContentView
{
	// Re-order pages
	int index = 0;
	for (PageView * page in pages) {
		CGFloat y = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? (scrollView.frame.size.height - 423.) / 2. : 0.;// The height of the background image of the pageView is 423pt
		CGRect frame = CGRectMake(index * scrollView.frame.size.width, (int)y, scrollView.frame.size.width, scrollView.frame.size.height);
		page.frame = frame;
		
		index++;
	}
	
	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * pages.count, 0.);
	
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:NO];
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
	PageView * pageView = pages[index];
	[pageView removeFromSuperview];
	[pages removeObjectAtIndex:index];
}

- (void)removeAllPages
{
	for (PageView * page in pages) {
		[page removeFromSuperview];
	}
	
	[pages removeAllObjects];
}

#pragma mark - Page and Page's Settings Selection

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (pageIndex < [Countdown allCountdowns].count) {
		
		pageControl.currentPage = pageIndex;
		CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageIndex, 0.);
		[scrollView setContentOffset:contentOffset animated:animated];
	}
}

- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	if (pageIndex < [Countdown allCountdowns].count) {
		
		[UIApplication sharedApplication].statusBarHidden = NO; // @TODO: Remove if unused
		
		if (!settingsViewController) {
			settingsViewController = [[SettingsViewController_Phone alloc] init];
			settingsViewController.delegate = self;
		}
		
		Countdown * currentCountdown = (Countdown *)[Countdown allCountdowns][pageControl.currentPage];
		settingsViewController.countdown = currentCountdown;
		
		UINavigationController * aNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
		
		if (!TARGET_IS_IOS7_OR_LATER()) {
		/* Force the tintColor of the navigationBar (done on "settingsViewController" when instanced, not each time when navigationController is created) */
		aNavigationController.navigationBar.tintColor = [UIColor defaultTintColor];
		}
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:aNavigationController animated:YES completion:NULL];
		
		[self stopUpdateTimeLabels];
	}
}

#pragma mark - Update Time Labels Managment

- (void)startUpdateTimeLabels
{
	[updateTimeLabelTimer invalidate];
	self.updateTimeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:1.
																 target:self
															   selector:@selector(updateTimeLabels)
															   userInfo:nil
																repeats:YES];
	[self updateTimeLabels];
}

- (void)updateTimeLabels
{
	int index = 0;
	for (PageView * page in pages) {
		
		if (ABS(pageControl.currentPage - index) <= 1) {// Update only the current page and it left and right neighbours
			dispatch_async(dispatch_get_main_queue(), ^{ [page update]; });
		}
		
		index++;
	}
}

- (void)stopUpdateTimeLabels
{
	[updateTimeLabelTimer invalidate];
	self.updateTimeLabelTimer = nil;
}

#pragma mark - SettingsViewControllerDelegate

- (void)settingsViewControllerDidFinish:(SettingsViewController_Phone *)controller
{
	[self reload];
	[self updateContentView];
	
	if ([Countdown allCountdowns].count > 0) {
		
		NSInteger pageIndex = [Countdown indexOfCountdown:controller.countdown];
		
		if (pageIndex == NSNotFound)
			pageIndex = pages.count - 1;// Select the last countdown
		
		pageControl.currentPage = pageIndex;
		CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageIndex, 0.);
		[scrollView setContentOffset:contentOffset animated:NO];
		
		[self startUpdateTimeLabels];
		
		[self dismissViewControllerAnimated:YES completion:NULL];
	} else {
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		
		[self dismissViewControllerAnimated:NO completion:NULL];
		[self presentViewController:navigationController animated:NO completion:NULL];
	}
	
}

#pragma mark - Go To Settings

- (void)pageViewWillShowSettings:(PageView *)page
{
	NSInteger index = [pages indexOfObject:page];
	if (index == NSNotFound)
		index = pageControl.currentPage;
	
	[self showSettingsForPageAtIndex:index animated:YES];
}

- (IBAction)showSettings:(id)sender
{
	[self showSettingsForPageAtIndex:pageControl.currentPage animated:YES];
}

- (void)pageViewWillShowDeleteConfirmation:(PageView *)page
{
	[UIView animateWithDuration:0.1
					 animations:^{ pageControl.alpha = 0.; }
					 completion:^(BOOL finished) { pageControl.hidden = YES; }];
}

- (void)pageViewDidScroll:(PageView *)page offset:(CGPoint)offset
{
	[self setBackgroundImageOffset:offset];
}

- (void)pageViewDidHideDeleteConfirmation:(PageView *)page
{
	pageControl.hidden = NO;
	[UIView animateWithDuration:0.1
					 animations:^{ pageControl.alpha = 1.; }
					 completion:^(BOOL finished) { scrollView.scrollEnabled = YES; }];
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
						 Countdown * countdown = [Countdown countdownAtIndex:(pageControl.currentPage)];
						 [Countdown removeCountdown:countdown];
						 
						 NSInteger count = [Countdown allCountdowns].count;
						 if (count > 0) {
							 
						 } else { // If we have deleted the last countdown, show editAllCountdowns: panel
							 EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
							 UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
							 
							 [self presentViewController:navigationController animated:YES completion:NULL];
						 }
						 if (TARGET_IS_IOS7_OR_LATER())
							 [self setNeedsStatusBarAppearanceUpdate];
						 
						 [self reload];
					 }];
}

#pragma mark - UIScrollViewDelegate

- (void)setBackgroundImageOffset:(CGPoint)point
{
	CGRect frame = _imageView.frame;
	frame.origin = point;
	_imageView.frame = frame;
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	CGFloat offset = scrollView.contentOffset.x / scrollView.frame.size.width;
	NSInteger index = MAX(roundf(offset), 0);
	pageControl.currentPage = index;
	PageView * pageView = pages[index];
	
	if (pageView.showDeleteConfirmation) {
		scrollView.scrollEnabled = NO;
		[pageView hideDeleteConfirmation];
		
	} else {
		UIColor * textColor = [UIColor textColorForPageStyle:pageView.style];
		pageControl.currentPageIndicatorTintColor = textColor;
		pageControl.pageIndicatorTintColor = [textColor colorWithAlphaComponent:0.5];
		
		if (scrollView.contentOffset.x < 0.) {
			[self setBackgroundImageOffset:CGPointMake(-scrollView.contentOffset.x, 0.)];
			
		} else if (scrollView.contentOffset.x > (scrollView.frame.size.width * (pageControl.numberOfPages - 1))) {
			[self setBackgroundImageOffset:CGPointMake((scrollView.frame.size.width * (pageControl.numberOfPages - 1)) - scrollView.contentOffset.x, 0.)];
		}
		
		if (TARGET_IS_IOS7_OR_LATER())
			[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)aScrollView
{
	NSInteger pageIndex = floor(scrollView.contentOffset.x / scrollView.frame.size.width);
	
	int index = 0;
	for (PageView * page in pages) {
		
		if (ABS(pageIndex - index) <= 1) {// Update only the current page and it left and right neighbours
			[page update];
		}
		
		index++;
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	PageView * pageView = pages[pageControl.currentPage];
	return (pageView.style == PageViewStyleDay || pageView.style == PageViewStyleSpring) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

#pragma mark - UIPageControl Managment

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self updateContentView];
}

@end
