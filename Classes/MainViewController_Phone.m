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

#import "UIColor+addition.h"


#import "NetworkStatus.h"

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
	
	scrollView.pagingEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.alwaysBounceHorizontal = YES;
	scrollView.delegate = self;
	
	pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
	
	/*
	[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidSynchronizeNotification
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  [self reload];
												  }];
	 */
}

- (void)viewWillAppear:(BOOL)animated
{
	[self reload];
	[self showDescriptions:YES animated:NO];
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	if (self.pages.count > 0) {
		[self reload];
	} else { // If no coutdowns to show (if the last coutdown has been deleted from delete button)
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		[self presentModalViewController:navigationController animated:NO];
	}
	
	[super viewDidAppear:animated];
}

#pragma mark - Current Page Index

- (NSInteger)selectedPageIndex
{
	return pageControl.currentPage;
}

#pragma mark - Page Memory Managing

- (void)loadPageAtIndex:(NSInteger)pageIndex
{
	[(PageView *)[self.pages objectAtIndex:pageIndex] load];
}

- (void)loadAllPages
{
	NSInteger pagesCount = self.pages.count;
	for (int i = 0; i < pagesCount; i++) {
		[self loadPageAtIndex:i];
	}
}

- (void)unloadPageAtIndex:(NSInteger)pageIndex
{
	[(PageView *)[self.pages objectAtIndex:pageIndex] unload];
}

- (void)unloadHiddenPages
{
	NSInteger pagesCount = self.pages.count;
	for (NSInteger i = 0; i < pagesCount; i++) {
		if (i != self.selectedPageIndex) {
			[self unloadPageAtIndex:i];
		}
	}
}

#pragma mark - Add Page

- (void)addPageWithCountDown:(Countdown *)aCountdown
{
	[self insertPageWithCountDown:aCountdown atIndex:pages.count];
}

- (void)insertPageWithCountDown:(Countdown *)aCountdown atIndex:(NSInteger)index
{
	NSDebugLog(@"insertPageWithCountDown: %@ atIndex: %d", aCountdown.name, index);
	
	CGFloat y = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? (scrollView.frame.size.height - 423. /* Height of the pageView */) / 2. : 0.;
	CGRect frame = CGRectMake(index * scrollView.frame.size.width, (int)y, scrollView.frame.size.width, scrollView.frame.size.height);
	
	PageView * page = nil;
	if (aCountdown.type == CountdownTypeTimer) {
		page = [[TimerPageView alloc] initWithFrame:frame];
	} else {
		page = [[CountdownPageView alloc] initWithFrame:frame];
	}
	
	page.delegate = self;
	page.countdown = aCountdown;
	page.orientation = self.interfaceOrientation;
	[pages insertObject:page atIndex:index];
	
	[self.scrollView addSubview:page];
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
		PageView * page = [pages objectAtIndex:index];
		
		/* If the type of page needs to change, remove the current page and re-create one */
		if ((countdown.type == CountdownTypeTimer && [page isKindOfClass:[CountdownPageView class]])
			|| (countdown.type == CountdownTypeDefault && [page isKindOfClass:[TimerPageView class]])) {
			[self removePageAtIndex:index];
			[self insertPageWithCountDown:countdown atIndex:index];
		}
		
		CGFloat y = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? (scrollView.frame.size.height - 423.) / 2. : 0.;// The height of the background image of the pageView is 423pt
		page.frame = CGRectMake(index * scrollView.frame.size.width, (int)y, scrollView.frame.size.width, scrollView.frame.size.height);
		
		page.countdown = countdown;
		page.orientation = self.interfaceOrientation;
		index++;
	}
	
	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * pages.count, 0.);
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:NO];
	
	pageControl.numberOfPages = pages.count;
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
		
		Countdown * currentCountdown = (Countdown *)[[Countdown allCountdowns] objectAtIndex:pageControl.currentPage];
		settingsViewController.countdown = currentCountdown;
		
		UINavigationController * aNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
		/* Force the tintColor of the navigationBar (done on "settingsViewController" when instanced, not each time when navigationController is created) */
		aNavigationController.navigationBar.tintColor = [UIColor defaultTintColor];
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentModalViewController:aNavigationController animated:YES];
		
		
		[self stopUpdateTimeLabels];
	}
}

#pragma mark - Update Time Labels Managment

- (void)startUpdateTimeLabels
{
	[updateTimeLabelTimer invalidate];
	self.updateTimeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updateTimeLabels) userInfo:nil repeats:YES];
	[self updateTimeLabels];
}

- (void)updateTimeLabels
{
	int index = 0;
	for (PageView * page in pages) {
		
		if (ABS(pageControl.currentPage - index) <= 1) {// Update only the current page and it left and right neighbours
			[page update];
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
		
		[self dismissModalViewControllerAnimated:YES];
	} else {
		EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
		
		[self dismissModalViewControllerAnimated:NO];
		[self presentModalViewController:navigationController animated:NO];
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

#pragma mark - Show Description Managment

- (void)showDescriptions:(BOOL)show animated:(BOOL)animated
{
	for (PageView * page in pages) {
		if ([page isKindOfClass:[CountdownPageView class]])
			[(CountdownPageView *)page showDescription:show animated:animated];
	}
}

#pragma mark - PageViewDelegate

- (void)viewDidSingleTap:(PageView *)page
{
	if ([page isKindOfClass:[CountdownPageView class]])
		[self showDescriptions:YES animated:YES];
}

- (void)viewDidDoubleTap:(PageView *)page
{
	// Unimplemented
}

#pragma mark - UIScrollViewDelegate

#if 0
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	CGFloat offsetPage = (scrollView.contentOffset.x / scrollView.frame.size.width);
	int currentPage = CLIP(offsetPage);
	
	int currentPage = (offsetPage - (int)offsetPage);
	
	
	Countdown * countdown = [Countdown countdownAtIndex:currentPage];
	
	if (countdown.type == CountdownTypeTimer) {
		backgroundView1.alpha = 1.;
		
		if ([pageControl respondsToSelector:@selector(pageIndicatorTintColor)]) {
			pageControl.pageIndicatorTintColor = [UIColor grayColor];
			pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
		}
		
	} else {
		backgroundView1.alpha = 0.;
		
		if ([pageControl respondsToSelector:@selector(pageIndicatorTintColor)]) {
			pageControl.pageIndicatorTintColor = [UIColor grayColor];
			pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
		}
	}
	
	
#if 0
	if ((offsetPage - currentPage) < -2. || 2. < (offsetPage - currentPage)) {
		if (offsetPage < (CGFloat)currentPage) {// If we are after the currentPage...
			
			if (currentPage > 0) {// ...and in the bounds
				
				Countdown * previousCountdown = [Countdown countdownAtIndex:(currentPage - 1)];
				backgroundView1.backgroundColor = (previousCountdown.type == CountdownTypeTimer) ? [UIColor lightGrayColor] : [UIColor viewFlipsideBackgroundColor];
				//[self.view sendSubviewToBack:backgroundView1];
				
				
				Countdown * currentCountdown = [Countdown countdownAtIndex:currentPage];
				backgroundView2.backgroundColor = (currentCountdown.type == CountdownTypeTimer) ? [UIColor lightGrayColor] : [UIColor viewFlipsideBackgroundColor];
				[self.view sendSubviewToBack:backgroundView2];
				
				/*
				 backgroundView1.backgroundColor = ((PageView *)[pages objectAtIndex:(currentPage - 1)]).backColor;// Previous page
				 backgroundView2.backgroundColor = ((PageView *)[pages objectAtIndex:currentPage]).backColor;// Current page
				 */
				//currentPage2 = currentPage - 1;
			}
			
		} else if (offsetPage > (CGFloat)currentPage) {// If we are before the currentPage...
			
			if ((currentPage + 1) < pages.count) {// ...and in the bounds
				
				Countdown * currentCountdown = [Countdown countdownAtIndex:currentPage];
				backgroundView1.backgroundColor = (currentCountdown.type == CountdownTypeTimer) ? [UIColor lightGrayColor] : [UIColor viewFlipsideBackgroundColor];
				
				Countdown * nextCountdown = [Countdown countdownAtIndex:(currentPage + 1)];
				backgroundView2.backgroundColor = (nextCountdown.type == CountdownTypeTimer) ? [UIColor lightGrayColor] : [UIColor viewFlipsideBackgroundColor];
				[self.view sendSubviewToBack:backgroundView2];
				
				/*
				 backgroundView1.backgroundColor = ((PageView *)[pages objectAtIndex:currentPage]).backColor;// Current page
				 backgroundView2.backgroundColor = ((PageView *)[pages objectAtIndex:(currentPage + 1)]).backColor;// Next page
				 */
				//currentPage2 = currentPage + 1;
			}
		}
		
		CGFloat offset = offsetPage - currentPage;
		backgroundView1.alpha = (1. - offset);
		//backgroundView2.alpha = offset;
	} else {
		backgroundView1.alpha = 0.;
		backgroundView2.alpha = 1.;
	}
#endif
}
#endif

- (void)scrollViewWillBeginDragging:(UIScrollView *)aScrollView
{
	[self showDescriptions:YES animated:NO];
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	pageControl.currentPage = floor(scrollView.contentOffset.x / scrollView.frame.size.width);
}

#pragma mark - UIPageControl Managment

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
	self.mainView = nil;
	self.label = nil;
	self.infoButton = nil;
	
	self.updateTimeLabelTimer = nil;
	self.animationDelay = nil;
	
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	for (PageView * page in pages) {
		page.orientation = toInterfaceOrientation;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self updateContentView];
}

@end
