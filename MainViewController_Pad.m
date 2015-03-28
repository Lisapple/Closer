//
//  ViewController.m
//  Closer
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController_Pad.h"

#import "SettingsViewController_Pad.h"
#import "CountdownPageView.h"
#import "TimerPageView.h"

#import "ImportFromCalendarViewController.h"
#import "ImportFromWebsiteViewController_Pad.h"
#import "ExportViewController.h"
#import "EditViewController.h"

#import "Countdown.h"

#import "NetworkStatus.h"

#import "NSObject+additions.h"

@interface MainViewController_Pad (PrivateMethods)

- (void)showNavigationBar:(NSInteger)navigationBarTag animated:(BOOL)animated;

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated;
- (void)deletePageViewAtIndex:(NSInteger)index animated:(NSInteger)animated;

#pragma mark Invalidate Layout
- (void)invalidateLayout;
- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

#pragma mark Update Layout
- (void)updateLayout;
- (void)updateLayoutWithAnimation:(BOOL)animated;
- (void)updateLayoutWithOrientation:(UIInterfaceOrientation)orientation;
- (void)updateLayoutWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

@end

#define kDefaultNavigationBar 1
#define kEditNavigationBar 2

#define kShareAlertTag 1234

@implementation MainViewController_Pad

#pragma mark - View lifecycle

- (void)showNavigationBar:(NSInteger)navigationBarTag
{
	[self showNavigationBar:navigationBarTag animated:YES];
}

- (void)showNavigationBar:(NSInteger)navigationBarTag animated:(BOOL)animated
{
	if (navigationBarTag == kEditNavigationBar) {
		
		UIBarButtonItem * editItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																				   target:self
																				   action:@selector(editAction:)];
		UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																					target:self
																					action:@selector(shareAction:)];
		[self.navigationItem setLeftBarButtonItems:@[editItem, shareItem]
										  animated:YES];
		
		UIBarButtonItem * doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				   target:self
																				   action:@selector(done:)];
		[self.navigationItem setRightBarButtonItem:doneItem animated:YES];
		
	} else {
		UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																				  target:self
																				  action:@selector(new:)];
		UIBarButtonItem * manageItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																		style:UIBarButtonItemStylePlain
																	   target:self
																	   action:@selector(editAll:)];
		self.navigationItem.leftBarButtonItems = @[addItem, manageItem];
		
		CGRect frame = CGRectMake(0., 0., 23., 23.);
		UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoLight];
		button.frame = frame;
		[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
		if (TARGET_IS_IOS7_OR_LATER())
			button.tintColor = self.view.window.tintColor;
		
		if (TARGET_IS_IOS7_OR_LATER()) {
			UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
			spaceItem.width = 90.;
			self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:button], spaceItem];
		} else {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
		}
		
		pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
		pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1. alpha:0.3];
		self.navigationItem.titleView = pageControl;
	}
	
	currentNavigationBarTag = navigationBarTag;
}

- (NSString *)proposedNameForType:(CountdownType)type
{
	NSString * name = (type == CountdownTypeTimer) ? NSLocalizedString(@"New Timer", nil) : NSLocalizedString(@"New Countdown", nil);
	NSArray * countdowns = [Countdown allCountdowns];
	
	int index = 1;
	while (1) {
		
		BOOL nameIsFree = YES;
		for (int i = 0; i < countdowns.count; i++) {
			Countdown * countdown = (Countdown *)countdowns[i];
			if ([countdown.name isEqualToString:name]) {
				nameIsFree = NO;
				break;
			}
		}
		
		if (nameIsFree)
			return name;
		
		if (type == CountdownTypeTimer)
			name = [NSString stringWithFormat:NSLocalizedString(@"New Timer %i", nil), index++];
		else
			name = [NSString stringWithFormat:NSLocalizedString(@"New Countdown %i", nil), index++];
	}
}

- (IBAction)new:(id)sender
{
	/* Create the countdown */
	__block Countdown * aCountDown = [[Countdown alloc] initWithIdentifier:nil];
	aCountDown.name = [self proposedNameForType:CountdownTypeCountdown];
	
	int numberOfRows = 2;
	int numberOfColumns = 2;
	NSInteger numberOfPages = ceil((pageViews.count + 1) / (float)(numberOfRows * numberOfColumns));
	CGRect rect = scrollView.bounds;
	rect.origin.x = (numberOfPages - 1) * rect.size.width;
	
	double delayInSeconds = 0.;
	if (scrollView.contentOffset.x < rect.origin.x) {// If the scrollView have to scroll, "pop" the new countdown after a delay
		
		/* Strech the scrollView to add a last page */
		scrollView.contentSize = CGSizeMake(numberOfPages * scrollView.frame.size.width, 0.);
		
		/* Scroll to the countdown new position */
		[scrollView setContentOffset:rect.origin
							animated:YES];
		
		pageControl.numberOfPages = numberOfPages;
		pageControl.currentPage = (numberOfPages - 1);
		
		delayInSeconds = 0.5;
	}
	
	[NSObject performBlock:^{
		
		[self createPageWithCountdown:aCountDown
							  atIndex:pageViews.count // After the last pageView ("pageViews.count - 1 + 1")
							 animated:YES];
		[NSObject performBlock:^{ [Countdown addCountdown:aCountDown]; }
					afterDelay:0.5];
	}
				afterDelay:delayInSeconds];
}

- (IBAction)editAll:(id)sender
{
	if (currentNavigationBarTag != kEditNavigationBar) {
		[self showNavigationBar:kEditNavigationBar animated:YES];
	}
}

- (IBAction)editAction:(id)sender
{
	if (!editPopover.isPopoverVisible) {
		EditViewController * editViewController = [[EditViewController alloc] init];
		editPopover = [[UIPopoverController alloc] initWithContentViewController:editViewController];
		[editPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
	}
}

- (IBAction)done:(id)sender
{
	if (currentNavigationBarTag == kEditNavigationBar) {
		[self showNavigationBar:kDefaultNavigationBar animated:YES];
	}
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	if (shareActionSheetShowing) {
		[shareActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
		shareActionSheetShowing = NO;
		[self shareAction:nil];
	}
}

- (IBAction)shareAction:(id)sender
{
	if (!shareActionSheetShowing) {
		BOOL isConnected = [NetworkStatus isConnected];
		shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil
													   delegate:self
											  cancelButtonTitle:nil
										 destructiveButtonTitle:nil
											  otherButtonTitles:NSLocalizedString(@"Import from Calendar", nil), nil];
		if (isConnected)
			[shareActionSheet addButtonWithTitle:NSLocalizedString(@"Import with Passwords", nil)];
		
		[shareActionSheet addButtonWithTitle:NSLocalizedString(@"Export", nil)];
		
		shareActionSheet.tag = kShareAlertTag;
		[shareActionSheet showFromBarButtonItem:(UIBarButtonItem *)sender
									   animated:NO];
		
		shareActionSheetShowing = YES;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kShareAlertTag) {// Import action sheet
		if (buttonIndex == 0) {
			ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] init];
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromCalendarViewController];
			navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController
							   animated:YES
							 completion:NULL];
		} else if (buttonIndex == 1 && [NetworkStatus isConnected]) { // Export with password (only if connected)
			
			/* Show an alertView to introduce the import from passwords (if not already done) */
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
			if (showsIntroductionMessage) {
				
				NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
				UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																	 message:message
																	delegate:self
														   cancelButtonTitle:NSLocalizedString(@"OK", nil)
														   otherButtonTitles:nil];
				[alertView show];
				
				[userDefaults setBool:YES forKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"];
			} else if (buttonIndex >= 1) {
				ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
				UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
				navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
				navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
				[self presentViewController:navigationController
								   animated:YES
								 completion:NULL];
			}
		}
	} else {// Information action sheet
		switch (buttonIndex) {
			case 0:// Show Countdowns Online
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://closer.lisacintosh.com/"]];
				break;
			case 1:// Feedback & Support
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/closer/"]];
				break;
			case 2:// Go to my website
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lisacintosh.com/"]];
				break;
			case 3: {// See all my applications
				/* Link via iTunes -> AppStore, I haven't found better! */
				NSString * iTunesLink = @"https://itunes.apple.com/us/artist/lisacintosh/id320891279?uo=4";// old link = http://search.itunes.apple.com/WebObjects/MZContentLink.woa/wa/link?path=apps%2flisacintosh
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
				
				/* Link via Safari -> iTunes -> AppStore */
				//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/lisacintosh/"]];
			}
				break;
			default:// Cancel
				break;
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kShareAlertTag)
		shareActionSheetShowing = NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
	navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:navigationController
					   animated:YES
					 completion:NULL];
}

- (void)showSettingsForPageAtIndex:(NSInteger)index
{
	/* Close the active settings */
	[self closeActiveSettings];
	
	SettingsViewController_Pad * settingsViewController = [[SettingsViewController_Pad alloc] init];
	settingsViewController.countdown = [Countdown countdownAtIndex:index];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	
	popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
	popover.delegate = self;
	
	if (!TARGET_IS_IOS7_OR_LATER())
		popover.popoverContentSize = CGSizeMake(popover.popoverContentSize.width, 480.);
	
	settingsViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	PageView * pageView = pageViews[index];
	CGRect rect = [self.view convertRect:pageView.infoButton.frame fromView:pageView];
	CGPoint offset = CGPointMake(60., 0.);
	if ([pageView isKindOfClass:TimerPageView.class])
		offset = CGPointMake(45., 60.);
	
	[popover presentPopoverFromRect:CGRectOffset(rect, offset.x, offset.y)
							 inView:self.view
		   permittedArrowDirections:(UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight)
						   animated:NO];
	
	currentSettingsPageIndex = index;
}

- (IBAction)showPopover:(id)sender
{
	[self showSettingsForPageAtIndex:1];
}

- (void)closeActiveSettings
{
	[popover dismissPopoverAnimated:YES];
	popover = nil;
    
    if (currentSettingsPageIndex >= 0) {
        [self reloadPageViewAtIndex:currentSettingsPageIndex];
        currentSettingsPageIndex = 0;
    }
}

- (IBAction)close:(id)sender
{
	[self closeActiveSettings];
}

- (IBAction)showSettings:(id)sender
{
	UIButton * button = sender;
	PageView * page = (PageView *)[[button superview] superview];
	if ([pageViews indexOfObject:page] != NSNotFound)
		[self showSettingsForPageAtIndex:[pageViews indexOfObject:page]];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © 2015, Lis@cintosh", nil), infoDictionary[@"CFBundleShortVersionString"]];
	
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:
								   NSLocalizedString(@"Show Countdowns Online", nil),
								   NSLocalizedString(@"Feedback & Support", nil),
								   NSLocalizedString(@"Go to my website", nil),
								   NSLocalizedString(@"See all my applications", nil), nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionSheet showInView:self.view];
}

- (void)handleTapFrom:(UIGestureRecognizer *)recognizer
{
	[self showSettingsForPageAtIndex:[pageViews indexOfObject:recognizer.view]];
}

#pragma mark - PageView Delegate

- (void)pageViewWillShowSettings:(PageView *)page
{
	[self showSettingsForPageAtIndex:[pageViews indexOfObject:page]];
}

- (BOOL)pageViewShouldShowDeleteConfirmation:(PageView *)page
{
	if (currentPageWithConfirmation) {
		[currentPageWithConfirmation hideDeleteConfirmation];
		[NSObject performBlock:^{ currentPageWithConfirmation = nil; }
					afterDelay:0.2];
		return NO;
	}
	return YES;
}

- (void)pageViewWillShowDeleteConfirmation:(PageView *)page
{
	currentPageWithConfirmation = page;
}

- (void)pageViewDidHideDeleteConfirmation:(PageView *)page
{
	currentPageWithConfirmation = nil;
}

- (void)pageViewDeleteButtonDidTap:(PageView *)page
{
	[self deleteCountdown:page];
}

#pragma mark - Delete Management

- (void)deleteCountdown:(PageView *)pageView
{
	NSUInteger index = [pageViews indexOfObject:pageView];
	if (index != NSNotFound) {
		NSInteger oldNumberOfCountdowns = [Countdown numberOfCountdowns];
		__block NSInteger oldNumberOfPages = ceil(oldNumberOfCountdowns / 4.);
		
		currentPageWithConfirmation = nil;// Unlink the page from the current page with confirmation
		[self deletePageViewAtIndex:index animated:YES];
		[Countdown removeCountdownAtIndex:index];
		[Countdown synchronize];
		
		[NSObject performBlock:^{
			NSInteger numberOfCountdowns = [Countdown numberOfCountdowns];
			NSInteger numberOfPages = ceil(numberOfCountdowns / 4.);
			if (oldNumberOfPages != numberOfPages) {// If the number of pages has changed
				
				/* // @FIXME: Don't scroll to last page
				 CGRect lastPageFrame = CGRectMake((numberOfPages - 1) * scrollView.frame.size.width, 0., scrollView.frame.size.width, scrollView.frame.size.height);
				 [scrollView scrollRectToVisible:lastPageFrame animated:YES];
				 pageControl.currentPage = (numberOfPages - 1);
				 */
				
				[NSObject performBlock:^{ [self updateLayoutWithAnimation:NO]; } afterDelay:0.25];
				
			} else {
				[self updateLayoutWithAnimation:YES];
			}
		}
					afterDelay:0.25];
	}
}

- (void)update
{
	for (PageView * pageView in pageViews)
		dispatch_async(dispatch_get_main_queue(), ^{ [pageView update]; });
}

#pragma mark - Invalidate Layout

- (void)invalidateLayout
{
	[self invalidateLayoutWithOrientation:self.interfaceOrientation
								 animated:NO];
}

- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated
{
	NSArray * countdowns = [Countdown allCountdowns];
	if (countdowns.count > pageViews.count) {// If we have countdown to add
		
		NSInteger count = pageViews.count;
		NSArray * newCountdowns = [countdowns subarrayWithRange:NSMakeRange(pageViews.count, (countdowns.count - pageViews.count))];
		for (Countdown * countdown in newCountdowns) {
			[self createPageWithCountdown:countdown atIndex:count animated:animated];
			++count;
		}
		
	} else if (countdowns.count < pageViews.count) {// If we have countdowns to remove
		
		NSRange range = NSMakeRange(countdowns.count, (pageViews.count - countdowns.count));
		for (PageView * pageView in [pageViews objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]])
			[self deletePageViewAtIndex:[pageViews indexOfObject:pageView] animated:YES];
	}
	
	/* Reload remaining PageView*/
	for (int i = 0; i < countdowns.count; i++) {
		[self reloadPageViewAtIndex:i];
	}
	
	[self updateLayoutWithOrientation:orientation
							 animated:animated];
}

#pragma mark - Update Layout

- (void)updateLayout
{
	[self updateLayoutWithOrientation:self.interfaceOrientation
							 animated:YES];
}

- (void)updateLayoutWithAnimation:(BOOL)animated
{
	[self updateLayoutWithOrientation:self.interfaceOrientation
							 animated:animated];
}

- (void)updateLayoutWithOrientation:(UIInterfaceOrientation)orientation
{
	[self updateLayoutWithOrientation:orientation
							 animated:YES];
}

- (void)updateLayoutWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated
{
	NSDebugLog(@"updateLayoutWithOrientation:animated: %@", (animated)? @"animated": @"not animated");
	
	const int numberOfRows = 2;
	const int numberOfColumns = 2;
	
	NSInteger numberOfItemsPerPage = 4;
	CGSize pageSize = CGSizeMake(384., 480.);
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		pageSize = CGSizeMake(341., 704.);
		numberOfItemsPerPage = 3;
	}
	
	NSInteger numberOfCountdowns = [Countdown numberOfCountdowns];
	int numberOfPage = ceil(numberOfCountdowns / (float)numberOfItemsPerPage);
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	int i = 0;
	for (PageView * pageView in pageViews) {
		
		int index = i % (numberOfRows * numberOfColumns);
		CGRect frame = CGRectMake(0., 0., pageSize.width, pageSize.height);
		
		if (UIInterfaceOrientationIsLandscape(orientation)) {
			
			frame.origin.x = (i * pageSize.width) + ceilf(index / 3.);
			
		} else {
			int row = index / numberOfRows;
			int col = index % numberOfRows;
			int page = i / (numberOfRows * numberOfColumns);
			
			int pageOffset = page * scrollView.frame.size.width;
			
			frame.origin.x = (col * pageSize.width) + frame.origin.x + pageOffset;
			frame.origin.y = (row * pageSize.height) + frame.origin.y;
		}
		pageView.frame = frame;
		
		++i;
	}
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	// @TODO: animate when the number of pages change
	scrollView.contentSize = CGSizeMake(numberOfPage * scrollView.frame.size.width, 0.);
	
	CGSize size = scrollView.frame.size;
	CGRect rect = CGRectMake(pageControl.currentPage * size.width, 0., size.width, size.height);
	[scrollView scrollRectToVisible:rect animated:NO];
	
	pageControl.numberOfPages = numberOfPage;
}

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated
{
	int numberOfRows = 2;
	int numberOfColumns = 2;
	
	CGSize pageSize = CGSizeMake(384., 480.);
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		pageSize = CGSizeMake(341., 704.);
	
	int i = index % (numberOfRows * numberOfColumns);
	int row = i / numberOfRows;
	int col = i % numberOfRows;
	NSInteger page = index / (numberOfRows * numberOfColumns);
	
	int pageOffset = page * scrollView.frame.size.width;
	
	CGFloat x = (col * pageSize.width) + pageOffset;
	CGFloat y = row * pageSize.height;
	CGRect rect = CGRectMake((int)x, (int)y, pageSize.width, pageSize.height);
	PageView * view = nil;
	if (countdown.type == CountdownTypeTimer)
		view = [[TimerPageView alloc] initWithFrame:rect];
	else
		view = [[CountdownPageView alloc] initWithFrame:rect];
	
	view.countdown = countdown;
	view.delegate = self;
	
	if (animated) {
		view.alpha = 0.;
		view.transform = CGAffineTransformMakeScale(0.1, 0.1);
	}
	
	[pageViews addObject:view];
	[scrollView addSubview:view];
	
	if (animated) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 view.alpha = 1.;
							 view.transform = CGAffineTransformIdentity;
						 }
						 completion:NULL];
	}
	
	return view;
}

- (void)reloadPageViewAtIndex:(NSInteger)index
{
	// @TODO: Change the type of countdown (if needed)
	// @TODO: Update the page
	
	Countdown * countdown = [Countdown allCountdowns][index];
	if (([pageViews[index] isKindOfClass:[CountdownPageView class]] && countdown.type != CountdownTypeCountdown)
		|| ([pageViews[index] isKindOfClass:[TimerPageView class]] && countdown.type != CountdownTypeTimer)) {
		
		NSDebugLog(@"Reloading page at index: %ld", (long)index);
		
		CGSize pageSize = CGSizeMake(384., 480.);
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
			pageSize = CGSizeMake(341., 704.);
		
		CGRect rect = CGRectMake(0., 0., pageSize.width, pageSize.height);
		
		PageView * pageView = nil;
		if (countdown.type == CountdownTypeTimer) {
			pageView = [[TimerPageView alloc] initWithFrame:rect];
		} else {
			pageView = [[CountdownPageView alloc] initWithFrame:rect];
		}
		
		pageView.countdown = countdown;
		pageView.delegate = self;
		
		[scrollView addSubview:pageView];
		[pageViews[index] removeFromSuperview];
		[pageViews replaceObjectAtIndex:index withObject:pageView];
	} else { // Just refresh the page view
		((PageView *)pageViews[index]).countdown = countdown;
	}
}

- (void)deletePageViewAtIndex:(NSInteger)index animated:(NSInteger)animated
{
	PageView * view = pageViews[index];
	view.alpha = 1.;
	view.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 view.alpha = 0.;
						 view.transform = CGAffineTransformMakeScale(0.1, 0.1);
					 }
					 completion:^(BOOL finished) { [view removeFromSuperview]; }];
	
	[pageViews removeObjectAtIndex:index];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (TARGET_IS_IOS7_OR_LATER())
		self.automaticallyAdjustsScrollViewInsets = NO;
	
	currentSettingsPageIndex = -1;
	
	[self showNavigationBar:kDefaultNavigationBar animated:NO];
	
	// landscape: 470 x 280
	// portrait: 300 x 423
	
	NSArray * countdowns = [Countdown allCountdowns];
	pageViews = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	
	int index = 0;
	for (Countdown * countdown in countdowns) {
		[self createPageWithCountdown:countdown
							  atIndex:index
							 animated:NO];
	}
	
	[self updateLayoutWithOrientation:self.interfaceOrientation animated:NO];
	
	if (!TARGET_IS_IOS7_OR_LATER()) {
		CGRect frame = scrollView.frame;
		frame.origin.y -= 20.;
		frame.size.height += 20.;
		scrollView.frame = frame;
	}
	
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	
	pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
	
	[NSTimer scheduledTimerWithTimeInterval:1.
									 target:self
								   selector:@selector(update)
								   userInfo:nil
									repeats:YES];
	[self update];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(closeActiveSettings)
												 name:@"SettingsViewControllerDidCloseNotification"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidSynchronizeNotification
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  [self update];
													  [self invalidateLayoutWithOrientation:self.interfaceOrientation animated:NO];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  [self update];
													  [self invalidateLayoutWithOrientation:self.interfaceOrientation animated:NO];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"CountdownDidCreateNewNotification"
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  /* Invalidate the layout */
													  [self invalidateLayout];
													  
													  /* Scroll to last page */
													  CGSize size = scrollView.frame.size;
													  CGRect rect = CGRectMake(pageControl.currentPage * size.width, 0., size.width, size.height);
													  [scrollView scrollRectToVisible:rect animated:YES];
													  pageControl.currentPage = (pageControl.numberOfPages - 1);
												  }];
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification
											   object:nil];
	
	/* Keyboard showing/hidding notifications */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	
	if (TARGET_IS_IOS7_OR_LATER())
		[self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self updateLayoutWithOrientation:self.interfaceOrientation animated:animated];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	if (currentSettingsPageIndex % 4 >= 2) { // If the index of the page is >= 2, the countdown is on the bottom line
		CGSize keyboardSize = [(notification.userInfo)[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		double duration = [(notification.userInfo)[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		[UIView animateWithDuration:duration
						 animations:^{
							 CGRect frame = scrollView.frame;
							 CGFloat height = MIN(keyboardSize.height, keyboardSize.width);// Get the real size from that the keyboard frame doesn't change depending of the rotation of the screen; the smaller value is the real height
							 frame.origin.y = ((TARGET_IS_IOS7_OR_LATER()) ? 64. : 44.) + 40. /* 40px margin*/ - height;
							 scrollView.frame = frame;
						 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	[UIView animateWithDuration:0.25
					 animations:^{
						 CGRect frame = scrollView.frame;
						 frame.origin.y = (TARGET_IS_IOS7_OR_LATER()) ? 64. : 44.;
						 
						 scrollView.frame = frame;
					 }];
}

#pragma mark - UIPopoverController delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self reloadPageViewAtIndex:currentSettingsPageIndex];
	currentSettingsPageIndex = 0;
}

#pragma mark - UIPageControl Managment

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
    if (pageIndex < pageControl.numberOfPages) {
        pageControl.currentPage = pageIndex;
        CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageIndex, 0.);
        [scrollView setContentOffset:contentOffset animated:animated];
    }
}

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	/* Hide the delete confirmation opened when the scroll starts */
	if (currentPageWithConfirmation) {
		//[self hideDeleteConfirmationOnPage:currentPageWithConfirmation];
		currentPageWithConfirmation = nil;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	pageControl.currentPage = floor(scrollView.contentOffset.x / scrollView.frame.size.width);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	UIInterfaceOrientation orientation = self.interfaceOrientation;
	[self updateLayoutWithOrientation:orientation animated:NO];
}

@end
