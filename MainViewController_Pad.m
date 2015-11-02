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
#import "NSDate+addition.h"

@interface MainViewController_Pad ()

@property (nonatomic, assign) NSInteger currentSettingsPageIndex, currentNavigationBarTag;
@property (nonatomic, strong) NSMutableArray <PageView *> * pageViews;
@property (nonatomic, strong) PageView * currentPageWithConfirmation;

@property (nonatomic, strong) UIPopoverController * popover, * editPopover;

- (void)showNavigationBar:(NSInteger)navigationBarTag animated:(BOOL)animated;

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated;
- (void)deletePageViewAtIndex:(NSInteger)index animated:(NSInteger)animated;

#pragma mark Invalidate Layout
- (void)invalidateLayout;
- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated;

#pragma mark Update Layout
- (void)updateLayout;
- (void)updateLayoutWithAnimation:(BOOL)animated;
- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation;
- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated;

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
																				   target:self action:@selector(editAction:)];
		UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																					target:self action:@selector(shareAction:)];
		[self.navigationItem setLeftBarButtonItems:@[ editItem, shareItem ]
										  animated:YES];
		
		UIBarButtonItem * doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				   target:self action:@selector(done:)];
		[self.navigationItem setRightBarButtonItem:doneItem animated:YES];
		
	} else {
		UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																				  target:self action:@selector(new:)];
		UIBarButtonItem * manageItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																		style:UIBarButtonItemStylePlain
																	   target:self action:@selector(editAll:)];
		self.navigationItem.leftBarButtonItems = @[ addItem, manageItem ];
		
		CGRect frame = CGRectMake(0., 0., 23., 23.);
		UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoLight];
		button.frame = frame;
		[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
		button.tintColor = self.view.window.tintColor;
		
		UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
		spaceItem.width = 90.;
		self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:button], spaceItem];
		
		_pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
		_pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1. alpha:0.3];
		self.navigationItem.titleView = _pageControl;
	}
	
	_currentNavigationBarTag = navigationBarTag;
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
	NSInteger numberOfPages = ceil((_pageViews.count + 1) / (float)(numberOfRows * numberOfColumns));
	CGRect rect = _scrollView.bounds;
	rect.origin.x = (numberOfPages - 1) * rect.size.width;
	
	double delayInSeconds = 0.;
	if (_scrollView.contentOffset.x < rect.origin.x) {// If the scrollView have to scroll, "pop" the new countdown after a delay
		
		/* Strech the scrollView to add a last page */
		_scrollView.contentSize = CGSizeMake(numberOfPages * _scrollView.frame.size.width, 0.);
		
		/* Scroll to the countdown new position */
		[_scrollView setContentOffset:rect.origin animated:YES];
		
		_pageControl.numberOfPages = numberOfPages;
		_pageControl.currentPage = (numberOfPages - 1);
		
		delayInSeconds = 0.5;
	}
	
	[NSObject performBlock:^{
		
		[self createPageWithCountdown:aCountDown
							  atIndex:_pageViews.count // After the last pageView ("pageViews.count - 1 + 1")
							 animated:YES];
		[NSObject performBlock:^{ [Countdown addCountdown:aCountDown]; }
					afterDelay:0.5];
	}
				afterDelay:delayInSeconds];
}

- (IBAction)editAll:(id)sender
{
	if (_currentNavigationBarTag != kEditNavigationBar) {
		[self showNavigationBar:kEditNavigationBar animated:YES];
	}
}

- (IBAction)editAction:(id)sender
{
	if (!_editPopover.isPopoverVisible) {
		EditViewController * editViewController = [[EditViewController alloc] init];
		_editPopover = [[UIPopoverController alloc] initWithContentViewController:editViewController];
		[_editPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
	}
}

- (IBAction)done:(id)sender
{
	if (_currentNavigationBarTag == kEditNavigationBar) {
		[self showNavigationBar:kDefaultNavigationBar animated:YES];
	}
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	if ([self.presentedViewController isKindOfClass:UIAlertController.class]) {
		[self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
	}
}

- (IBAction)shareAction:(id)sender
{
	UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import from Calendar", nil) style:UIAlertActionStyleDefault handler:
							^(UIAlertAction * _Nonnull action) {
								ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] init];
								UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromCalendarViewController];
								navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
								navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
								[self presentViewController:navigationController animated:YES completion:NULL];
							}]];
	if ([NetworkStatus isConnected]) {
		[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import with Passwords", nil) style:UIAlertActionStyleDefault handler:
								^(UIAlertAction * _Nonnull action) {
									/* Show an alertView to introduce the import from passwords (if not already done) */
									NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
									if (showsIntroductionMessage) {
										
										NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
										UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																										message:message
																								 preferredStyle:UIAlertControllerStyleAlert];
										[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:
														  ^(UIAlertAction * _Nonnull action) {
															  ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
															  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
															  navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
															  navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
															  [self presentViewController:navigationController animated:YES completion:NULL]; }]];
										alert.view.tintColor = [UIColor darkGrayColor];
										[self presentViewController:alert animated:YES completion:nil];
										
										[userDefaults setBool:YES forKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"];
									} else {
										ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
										UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
										navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
										navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
										[self presentViewController:navigationController animated:YES completion:NULL];
									}
								}]];
	}
	
	[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Export", nil) style:UIAlertActionStyleDefault handler:
							^(UIAlertAction * _Nonnull action) {
								ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
								UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
								navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
								navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
								[self presentViewController:navigationController animated:YES completion:NULL];
							}]];
	actionSheet.view.tintColor = [UIColor defaultTintColor];
	actionSheet.popoverPresentationController.barButtonItem = (UIBarButtonItem *)sender;
	[self presentViewController:actionSheet animated:NO completion:NULL];
}

- (void)showSettingsForPageAtIndex:(NSInteger)index
{
	/* Close the active settings */
	[self closeActiveSettings];
	
	SettingsViewController_Pad * settingsViewController = [[SettingsViewController_Pad alloc] init];
	settingsViewController.countdown = [Countdown countdownAtIndex:index];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	
	_popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
	_popover.delegate = self;
	
	settingsViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	PageView * pageView = _pageViews[index];
	CGRect rect = [self.view convertRect:pageView.infoButton.frame fromView:pageView];
	CGPoint offset = CGPointMake(60., 0.);
	if ([pageView isKindOfClass:TimerPageView.class])
		offset = CGPointMake(45., 60.);
	
	[_popover presentPopoverFromRect:CGRectOffset(rect, offset.x, offset.y)
							 inView:self.view
		   permittedArrowDirections:(UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight)
						   animated:NO];
	
	_currentSettingsPageIndex = index;
}

- (IBAction)showPopover:(id)sender
{
	[self showSettingsForPageAtIndex:1];
}

- (void)closeActiveSettings
{
	[_popover dismissPopoverAnimated:YES];
	_popover = nil;
    
    if (_currentSettingsPageIndex >= 0) {
        [self reloadPageViewAtIndex:_currentSettingsPageIndex];
        _currentSettingsPageIndex = 0;
    }
}

- (IBAction)close:(id)sender
{
	[self closeActiveSettings];
}

- (IBAction)showSettings:(id)sender
{
	UIButton * button = sender;
	PageView * page = (PageView *)button.superview.superview;
	if ([_pageViews indexOfObject:page] != NSNotFound)
		[self showSettingsForPageAtIndex:[_pageViews indexOfObject:page]];
}

- (IBAction)moreInfo:(UIButton *)sender
{
	NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © %lu, Lis@cintosh", nil), infoDictionary[@"CFBundleShortVersionString"], [NSDate date].year];
	UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"closer.lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://closer.lisacintosh.com"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"support.lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/closer/"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lisacintosh.com/"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"appstore.com/lisacintosh" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://appstore.com/lisacintosh/"]]; }]];
	actionSheet.view.tintColor = [UIColor defaultTintColor];
	actionSheet.popoverPresentationController.sourceView = sender;
	actionSheet.popoverPresentationController.sourceRect = sender.bounds;
	[self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)handleTapFrom:(UIGestureRecognizer *)recognizer
{
	[self showSettingsForPageAtIndex:[_pageViews indexOfObject:(PageView *)recognizer.view]];
}

#pragma mark - PageView Delegate

- (void)pageViewWillShowSettings:(PageView *)page
{
	[self showSettingsForPageAtIndex:[_pageViews indexOfObject:page]];
}

- (BOOL)pageViewShouldShowDeleteConfirmation:(PageView *)page
{
	if (_currentPageWithConfirmation) {
		[_currentPageWithConfirmation hideDeleteConfirmation];
		[NSObject performBlock:^{ self.currentPageWithConfirmation = nil; }
					afterDelay:0.2];
		return NO;
	}
	return YES;
}

- (void)pageViewWillShowDeleteConfirmation:(PageView *)page
{
	_currentPageWithConfirmation = page;
}

- (void)pageViewDidHideDeleteConfirmation:(PageView *)page
{
	_currentPageWithConfirmation = nil;
}

- (void)pageViewDeleteButtonDidTap:(PageView *)page
{
	[self deleteCountdown:page];
}

#pragma mark - Delete Management

- (void)deleteCountdown:(PageView *)pageView
{
	NSUInteger index = [_pageViews indexOfObject:pageView];
	if (index != NSNotFound) {
		NSInteger oldNumberOfCountdowns = [Countdown numberOfCountdowns];
		__block NSInteger oldNumberOfPages = ceil(oldNumberOfCountdowns / 4.);
		
		_currentPageWithConfirmation = nil;// Unlink the page from the current page with confirmation
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
	for (PageView * pageView in _pageViews)
		dispatch_async(dispatch_get_main_queue(), ^{ [pageView update]; });
}

#pragma mark - Invalidate Layout

- (void)invalidateLayout
{
	[self invalidateLayoutWithOrientation:self.currentOrientation
								 animated:NO];
}

- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated
{
	NSArray * countdowns = [Countdown allCountdowns];
	if (countdowns.count > _pageViews.count) {// If we have countdown to add
		
		NSInteger count = _pageViews.count;
		NSArray * newCountdowns = [countdowns subarrayWithRange:NSMakeRange(_pageViews.count, (countdowns.count - _pageViews.count))];
		for (Countdown * countdown in newCountdowns) {
			[self createPageWithCountdown:countdown atIndex:count animated:animated];
			++count;
		}
		
	} else if (countdowns.count < _pageViews.count) {// If we have countdowns to remove
		
		NSRange range = NSMakeRange(countdowns.count, (_pageViews.count - countdowns.count));
		for (PageView * pageView in [_pageViews objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]])
			[self deletePageViewAtIndex:[_pageViews indexOfObject:pageView] animated:YES];
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
	[self updateLayoutWithOrientation:self.currentOrientation
							 animated:YES];
}

- (void)updateLayoutWithAnimation:(BOOL)animated
{
	[self updateLayoutWithOrientation:self.currentOrientation
							 animated:animated];
}

- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation
{
	[self updateLayoutWithOrientation:orientation
							 animated:YES];
}

- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientationMask animated:(BOOL)animated
{
	NSDebugLog(@"updateLayoutWithOrientation:animated: %@", (animated)? @"animated": @"not animated");
	
	const int numberOfRows = 2;
	const int numberOfColumns = 2;
	
	NSInteger numberOfItemsPerPage = 4;
	if (orientationMask & UIInterfaceOrientationMaskLandscape) {
		numberOfItemsPerPage = 3;
	}
	
	NSInteger numberOfCountdowns = [Countdown numberOfCountdowns];
	int numberOfPage = ceil(numberOfCountdowns / (float)numberOfItemsPerPage);
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	CGSize screenSize = ([UIScreen mainScreen].bounds.size);
	if /**/ (orientationMask & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width) {
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	}
	else if (orientationMask & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width) {
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	}
	CGSize pageSize = (orientationMask & UIInterfaceOrientationMaskLandscape) ?
		CGSizeMake(screenSize.width / 3., screenSize.height - self.topLayoutGuide.length) :
		CGSizeMake(screenSize.width / 2., (screenSize.height - self.topLayoutGuide.length) / 2.);
	
	int i = 0;
	for (PageView * pageView in _pageViews) {
		
		int index = i % (numberOfRows * numberOfColumns);
		CGRect frame = CGRectMake(0., 0., pageSize.width, pageSize.height);
		
		if (orientationMask & UIInterfaceOrientationMaskLandscape) {
			
			frame.origin.x = (i * pageSize.width) + ceilf(index / 3.);
			
		} else {
			int row = index / numberOfRows;
			int col = index % numberOfRows;
			int page = i / (numberOfRows * numberOfColumns);
			
			int pageOffset = page * screenSize.width;
			
			frame.origin.x = (col * pageSize.width) + frame.origin.x + pageOffset;
			frame.origin.y = (row * pageSize.height) + frame.origin.y;
		}
		pageView.frame = frame;
		
		++i;
	}
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	// @TODO: animate when the number of pages change
	_scrollView.contentSize = CGSizeMake(numberOfPage * screenSize.width, 0.);
	
	CGRect rect = CGRectMake(_pageControl.currentPage * screenSize.width, 0., screenSize.width, screenSize.height);
	[_scrollView scrollRectToVisible:rect animated:NO];
	
	_pageControl.numberOfPages = numberOfPage;
}

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated
{
	int numberOfRows = 2;
	int numberOfColumns = 2;
	
	int i = index % (numberOfRows * numberOfColumns);
	int row = i / numberOfRows;
	int col = i % numberOfRows;
	NSInteger page = index / (numberOfRows * numberOfColumns);
	
	int pageOffset = page * _scrollView.frame.size.width;
	
	CGSize screenSize = ([UIScreen mainScreen].bounds.size);
	if /**/ (self.currentOrientation & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width) {
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	}
	else if (self.currentOrientation & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width) {
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	}
	CGSize pageSize = (self.currentOrientation & UIInterfaceOrientationMaskLandscape) ?
		CGSizeMake(screenSize.width / 3., screenSize.height - self.topLayoutGuide.length) :
		CGSizeMake(screenSize.width / 2., (screenSize.height - self.topLayoutGuide.length) / 2.);
	
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
	
	[_pageViews addObject:view];
	[_scrollView addSubview:view];
	
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
	if (([_pageViews[index] isKindOfClass:[CountdownPageView class]] && countdown.type != CountdownTypeCountdown)
		|| ([_pageViews[index] isKindOfClass:[TimerPageView class]] && countdown.type != CountdownTypeTimer)) {
		
		NSDebugLog(@"Reloading page at index: %ld", (long)index);
		
		CGSize screenSize = ([UIScreen mainScreen].bounds.size);
		if /**/ (self.currentOrientation & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width) {
			screenSize = CGSizeMake(screenSize.height, screenSize.width);
		}
		else if (self.currentOrientation & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width) {
			screenSize = CGSizeMake(screenSize.height, screenSize.width);
		}
		CGSize pageSize = (self.currentOrientation & UIInterfaceOrientationMaskLandscape) ?
			CGSizeMake(screenSize.width / 3., screenSize.height - self.topLayoutGuide.length) :
			CGSizeMake(screenSize.width / 2., (screenSize.height - self.topLayoutGuide.length) / 2.);
		CGRect rect = CGRectMake(0., 0., pageSize.width, pageSize.height);
		
		PageView * pageView = nil;
		if (countdown.type == CountdownTypeTimer) {
			pageView = [[TimerPageView alloc] initWithFrame:rect];
		} else {
			pageView = [[CountdownPageView alloc] initWithFrame:rect];
		}
		
		pageView.countdown = countdown;
		pageView.delegate = self;
		
		[_scrollView addSubview:pageView];
		[_pageViews[index] removeFromSuperview];
		_pageViews[index] = pageView;
	} else { // Just refresh the page view
		_pageViews[index].countdown = countdown;
	}
}

- (void)deletePageViewAtIndex:(NSInteger)index animated:(NSInteger)animated
{
	PageView * view = _pageViews[index];
	view.alpha = 1.;
	view.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 view.alpha = 0.;
						 view.transform = CGAffineTransformMakeScale(0.1, 0.1);
					 }
					 completion:^(BOOL finished) { [view removeFromSuperview]; }];
	
	[_pageViews removeObjectAtIndex:index];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.automaticallyAdjustsScrollViewInsets = NO;
	
	_currentSettingsPageIndex = -1;
	_currentOrientation = ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskLandscape;
	
	[self showNavigationBar:kDefaultNavigationBar animated:NO];
	
	NSArray * countdowns = [Countdown allCountdowns];
	_pageViews = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	
	int index = 0;
	for (Countdown * countdown in countdowns) {
		[self createPageWithCountdown:countdown atIndex:index animated:NO];
		++index;
	}
	
	[self updateLayoutWithOrientation:self.currentOrientation animated:NO];
	
	_scrollView.pagingEnabled = YES;
	_scrollView.delegate = self;
	_pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
	
	[NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(update)
								   userInfo:nil repeats:YES];
	[self update];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeActiveSettings)
												 name:@"SettingsViewControllerDidCloseNotification" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidSynchronizeNotification object:nil queue:nil
												  usingBlock:^(NSNotification *note) {
													  [self update];
													  [self invalidateLayoutWithOrientation:self.currentOrientation animated:NO];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification object:nil queue:nil
												  usingBlock:^(NSNotification *note) {
													  [self update];
													  [self invalidateLayoutWithOrientation:self.currentOrientation animated:NO];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"CountdownDidCreateNewNotification" object:nil queue:nil
												  usingBlock:^(NSNotification *note) {
													  /* Invalidate the layout */
													  [self invalidateLayout];
													  
													  /* Scroll to last page */
													  CGSize size = _scrollView.frame.size;
													  CGRect rect = CGRectMake(_pageControl.currentPage * size.width, 0., size.width, size.height);
													  [_scrollView scrollRectToVisible:rect animated:YES];
													  _pageControl.currentPage = (_pageControl.numberOfPages - 1);
												  }];
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification object:nil];
	
	/* Keyboard showing/hidding notifications */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
	[self setNeedsStatusBarAppearanceUpdate];
	
	[_pageControl addObserver:self forKeyPath:@"currentPage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
}

- (void)dealloc
{
	[_pageControl removeObserver:self forKeyPath:@"currentPage"];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self updateLayoutWithOrientation:self.currentOrientation animated:animated];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	if (_currentSettingsPageIndex % 4 >= 2) { // If the index of the page is >= 2, the countdown is on the bottom line
		CGSize keyboardSize = [(notification.userInfo)[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		double duration = [(notification.userInfo)[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		[UIView animateWithDuration:duration
						 animations:^{
							 CGRect frame = _scrollView.frame;
							 CGFloat height = MIN(keyboardSize.height, keyboardSize.width);// Get the real size from that the keyboard frame doesn't change depending of the rotation of the screen; the smaller value is the real height
							 frame.origin.y = 64. + 40. /* 40px margin*/ - height;
							 _scrollView.frame = frame;
						 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	[UIView animateWithDuration:0.25
					 animations:^{
						 CGRect frame = _scrollView.frame;
						 frame.origin.y = 64.;
						 _scrollView.frame = frame;
					 }];
}

#pragma mark - UIPopoverController delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self reloadPageViewAtIndex:_currentSettingsPageIndex];
	_currentSettingsPageIndex = 0;
}

#pragma mark - UIPageControl Managment

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if (object == _pageControl && [keyPath isEqualToString:@"currentPage"]) {
		
		NSUInteger oldPage = [change[NSKeyValueChangeOldKey] integerValue];
		NSUInteger location = MIN(_pageViews.count - 1, oldPage * 4);
		NSUInteger length = MIN(_pageViews.count - 1 - location, 4);
		NSArray <PageView *> * pages = [_pageViews subarrayWithRange:NSMakeRange(location, length)];
		for (PageView * pageView in pages) {
			[pageView viewDidHide:YES]; }
		
		NSUInteger currentPage = [change[NSKeyValueChangeNewKey] integerValue];
		location = MIN(_pageViews.count - 1, currentPage * 4);
		length = MIN(_pageViews.count - 1 - location, 4);
		pages = [_pageViews subarrayWithRange:NSMakeRange(location, length)];
		for (PageView * pageView in pages) {
			[pageView viewWillShow:YES]; }
	}
}

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
    if (pageIndex < _pageControl.numberOfPages) {
        _pageControl.currentPage = pageIndex;
        CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * pageIndex, 0.);
        [_scrollView setContentOffset:contentOffset animated:animated];
    }
}

- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _pageControl.currentPage, 0.);
	[_scrollView setContentOffset:contentOffset animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	/* Hide the delete confirmation opened when the scroll starts */
	if (_currentPageWithConfirmation) {
		//[self hideDeleteConfirmationOnPage:currentPageWithConfirmation];
		_currentPageWithConfirmation = nil;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	_pageControl.currentPage = floor(_scrollView.contentOffset.x / _scrollView.frame.size.width);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	_currentOrientation = (size.height > size.width) ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskLandscape;
	[self updateLayout];
}

@end
