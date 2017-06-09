//
//  ViewController.m
//  Closer
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController_Pad.h"

#import "CountdownPageView.h"
#import "TimerPageView.h"
#import "PageViewContainer.h"

#import "ImportFromCalendarViewController.h"
#import "ImportFromWebsiteViewController_Pad.h"
#import "ExportViewController.h"
#import "EditViewController.h"

#import "NetworkStatus.h"

#import "NSObject+additions.h"
#import "NSDate+addition.h"
#import "Countdown+addition.h"

@interface MainViewController_Pad ()

@property (nonatomic, assign) NSInteger currentSettingsPageIndex, currentNavigationBarTag;
@property (nonatomic, strong) NSMutableArray <PageViewContainer *> * containers;

- (void)showNavigationBar:(NSInteger)navigationBarTag animated:(BOOL)animated;

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated;
- (void)deletePageAtIndex:(NSInteger)index animated:(NSInteger)animated;

// Invalidate Layout
- (void)invalidateLayout;
- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated;

// Update Layout
- (void)updateLayout;
- (void)updateLayoutWithAnimation:(BOOL)animated;
- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated;

@end

#define kDefaultNavigationBar 1
#define kEditNavigationBar 2

@implementation MainViewController_Pad

#pragma mark - Actions

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
		
		self.navigationItem.titleView = nil;
		
	} else {
		UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																				  target:self action:@selector(new:)];
		UIBarButtonItem * manageItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																		style:UIBarButtonItemStylePlain
																	   target:self action:@selector(editAll:)];
		self.navigationItem.leftBarButtonItems = @[ addItem, manageItem ];
		
		UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoLight];
		button.frame = CGRectMake(0., 0., 23., 23.);
		[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
		button.tintColor = self.view.window.tintColor;
		
		UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
		spaceItem.width = 90.;
		self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:button], spaceItem];
		
		self.navigationItem.titleView = _pageControl;
	}
	
	_currentNavigationBarTag = navigationBarTag;
}

- (IBAction)new:(id)sender
{
	/* Create the countdown */
	__block Countdown * aCountDown = [[Countdown alloc] initWithIdentifier:nil];
	aCountDown.name = [Countdown proposedNameForType:CountdownTypeCountdown];
	
	int numberOfRows = 2;
	int numberOfColumns = 2;
	NSInteger numberOfPages = ceil((_containers.count + 1) / (float)(numberOfRows * numberOfColumns));
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
							  atIndex:_containers.count // After the last pageView ("pageViews.count - 1 + 1")
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
	EditViewController * editViewController = [[EditViewController alloc] initWithStyle:UITableViewStyleGrouped];
	editViewController.modalPresentationStyle = UIModalPresentationPopover;
	[self presentViewController:editViewController animated:NO completion:^{
		editViewController.popoverPresentationController.passthroughViews = @[]; // Ignore other navBar buttons interaction
	}];
	
	UIPopoverPresentationController * presentator = editViewController.popoverPresentationController;
	presentator.permittedArrowDirections = UIPopoverArrowDirectionUp;
	presentator.barButtonItem = sender;
}

- (IBAction)done:(id)sender
{
	if (_currentNavigationBarTag == kEditNavigationBar)
		[self showNavigationBar:kDefaultNavigationBar animated:YES];
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	if ([self.presentedViewController isKindOfClass:UIAlertController.class])
		[self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)shareAction:(id)sender
{
	UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import from Calendar", nil) style:UIAlertActionStyleDefault handler:
							^(UIAlertAction * action) {
								ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] initWithStyle:UITableViewStyleGrouped];
								UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromCalendarViewController];
								navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
								navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
								[self presentViewController:navigationController animated:YES completion:NULL];
							}]];
	if ([NetworkStatus isConnected]) {
		[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import with Passwords", nil) style:UIAlertActionStyleDefault handler:
								^(UIAlertAction * action) {
									/* Show an alertView to introduce the import from passwords (if not already done) */
									NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
									if (showsIntroductionMessage) {
										
										NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
										UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																										message:message
																								 preferredStyle:UIAlertControllerStyleAlert];
										[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
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
							^(UIAlertAction * action) {
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

- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
	/* Close the active settings */
	[self closeActiveSettings];
	
	_settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	_settingsViewController.countdown = [Countdown countdownAtIndex:pageIndex];
	_settingsViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:_settingsViewController];
	navigationController.modalPresentationStyle = UIModalPresentationPopover;
	[self presentViewController:navigationController animated:NO completion:nil];
	
	PageViewContainer * container = _containers[pageIndex];
	CGRect rect = [self.view convertRect:container.infoButton.frame fromView:container];
	
	UIPopoverPresentationController * presentator = navigationController.popoverPresentationController;
	presentator.permittedArrowDirections = (UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight);
	presentator.sourceView = self.view;
	presentator.sourceRect = rect;
	presentator.delegate = self;
	
	_currentSettingsPageIndex = pageIndex;
}

- (IBAction)showPopover:(id)sender
{
	[self showSettingsForPageAtIndex:1 animated:YES];
}

- (void)closeActiveSettings
{
	[_settingsViewController dismissViewControllerAnimated:true completion:nil];
	
	if (_currentSettingsPageIndex >= 0) {
		[self reloadPageAtIndex:_currentSettingsPageIndex];
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
	PageViewContainer * container = (PageViewContainer *)button.superview;
	if ([_containers indexOfObject:container] != NSNotFound)
		[self showSettingsForPageAtIndex:[_containers indexOfObject:container] animated:YES];
}

- (IBAction)moreInfo:(UIButton *)sender
{
	NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nLis@cintosh, %lu", nil),
						infoDictionary[@"CFBundleShortVersionString"], [NSDate date].year];
	UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	NSDictionary<NSString *, NSString *> * labels = @{ @"closer.lisacintosh.com" : @"https://closer.lisacintosh.com",
													   @"support.lisacintosh.com" : @"https://support.lisacintosh.com/closer/",
													   @"lisacintosh.com" : @"https://lisacintosh.com/",
													   @"appstore.com/lisacintosh" : @"https://appstore.com/lisacintosh/" };
	for (NSString * label in labels) {
		[actionSheet addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			NSURL * url = [NSURL URLWithString:labels[label]];
			if ([UIApplication instancesRespondToSelector:@selector(openURL:options:completionHandler:)])
				[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
			else
IGNORE_DEPRECATION_BEGIN
				[[UIApplication sharedApplication] openURL:url];
IGNORE_DEPRECATION_END
			
#if ANALYTICS_ENABLED
			[Answers logCustomEventWithName:@"open-about-url" customAttributes:@{ @"url" : url }];
#endif
			
		}]];
	}
	actionSheet.view.tintColor = [UIColor defaultTintColor];
	[self presentViewController:actionSheet animated:YES completion:nil];
	
	actionSheet.popoverPresentationController.sourceView = sender;
	actionSheet.popoverPresentationController.sourceRect = sender.bounds;
}

- (void)handleTapFrom:(UIGestureRecognizer *)recognizer
{
	[self showSettingsForPageAtIndex:[_containers indexOfObject:(PageViewContainer *)recognizer.view] animated:YES];
}

#pragma mark - PageViewContainer delegate

- (void)containerWillShowSettings:(PageViewContainer *)container
{
	[self showSettingsForPageAtIndex:[_containers indexOfObject:container] animated:YES];
}

- (void)containerWillResetTimer:(PageViewContainer *)container
{
	TimerPageView * page = (TimerPageView *)container.pageView;
	[page reset];
}

- (void)containerWillResumeTimer:(PageViewContainer *)container
{
	TimerPageView * page = (TimerPageView *)container.pageView;
	[page tooglePause];
}

#pragma mark - Delete management

- (void)deleteCountdown:(PageViewContainer *)container // ???: USED?
{
	NSUInteger index = [_containers indexOfObject:container];
	if (index != NSNotFound) {
		NSInteger oldNumberOfCountdowns = [Countdown numberOfCountdowns];
		__block NSInteger oldNumberOfPages = ceil(oldNumberOfCountdowns / 4.);
		
		[self deletePageAtIndex:index animated:YES];
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
	for (PageViewContainer * container in _containers)
		dispatch_async(dispatch_get_main_queue(), ^{ [container update]; });
}

#pragma mark - Invalidate layout

- (void)invalidateLayout
{
	[self invalidateLayoutWithOrientation:self.currentOrientation
								 animated:NO];
}

- (void)invalidateLayoutWithOrientation:(UIInterfaceOrientationMask)orientation animated:(BOOL)animated
{
	NSArray * countdowns = [Countdown allCountdowns];
	if (countdowns.count > _containers.count) { // If we have countdown to add
		NSInteger count = _containers.count;
		NSArray * newCountdowns = [countdowns subarrayWithRange:NSMakeRange(_containers.count, (countdowns.count - _containers.count))];
		for (Countdown * countdown in newCountdowns) {
			[self createPageWithCountdown:countdown atIndex:count animated:animated];
			++count;
		}
	} else if (countdowns.count < _containers.count) { // If we have countdowns to remove
		NSRange range = NSMakeRange(countdowns.count, (_containers.count - countdowns.count));
		for (PageViewContainer * container in [_containers objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]])
			[self deletePageAtIndex:[_containers indexOfObject:container] animated:YES];
	}
	
	/* Reload remaining PageView*/
	for (int i = 0; i < countdowns.count; i++)
		[self reloadPageAtIndex:i];
	
	[self updateLayoutWithOrientation:orientation animated:animated];
}

#pragma mark - Update layout

- (void)updateLayout
{
	[self updateLayoutWithAnimation:YES];
}

- (void)updateLayoutWithAnimation:(BOOL)animated
{
	[self updateLayoutWithOrientation:self.currentOrientation
							 animated:animated];
}

- (void)updateLayoutWithOrientation:(UIInterfaceOrientationMask)orientationMask animated:(BOOL)animated
{
	NSDebugLog(@"updateLayoutWithOrientation:animated: %@", (animated)? @"animated": @"not animated");
	
	const NSInteger numberOfRows = 2;
	const NSInteger numberOfColumns = 2;
	const NSInteger numberOfItemsPerPage = (orientationMask & UIInterfaceOrientationMaskLandscape) ? 3 : 4;
	
	NSInteger numberOfCountdowns = [Countdown numberOfCountdowns];
	int numberOfPage = ceil(numberOfCountdowns / (float)numberOfItemsPerPage);
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	if /**/ (orientationMask & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	else if (orientationMask & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	
	const CGFloat topMargin = 20 + self.topLayoutGuide.length + self.navigationController.navigationBar.frame.size.height;
	CGSize pageSize = (orientationMask & UIInterfaceOrientationMaskLandscape) ?
		CGSizeMake(screenSize.width / 3., screenSize.height - topMargin) :
		CGSizeMake(screenSize.width / 2., (screenSize.height - topMargin) / 2.);
	
	int i = 0;
	for (PageViewContainer * container in _containers) {
		const int index = i % (numberOfRows * numberOfColumns);
		CGRect frame = CGRectMake(0., 0., pageSize.width, pageSize.height);
		
		if (orientationMask & UIInterfaceOrientationMaskLandscape) {
			frame.origin.x = (i * pageSize.width) + ceilf(index / 3.);
		} else {
			const int row = index / numberOfRows;
			const int col = index % numberOfRows;
			const int page = i / (numberOfRows * numberOfColumns);
			
			int pageOffset = page * screenSize.width;
			frame.origin.x = (col * pageSize.width) + frame.origin.x + pageOffset;
			frame.origin.y = (row * pageSize.height) + frame.origin.y;
		}
		container.frame = frame;
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
	const NSInteger numberOfRows = 2;
	const NSInteger numberOfColumns = 2;
	
	const NSInteger i = index % (numberOfRows * numberOfColumns);
	const NSInteger row = i / numberOfRows;
	const NSInteger col = i % numberOfRows;
	NSInteger page = index / (numberOfRows * numberOfColumns);
	
	CGSize screenSize = ([UIScreen mainScreen].bounds.size);
	if /**/ (self.currentOrientation & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	else if (self.currentOrientation & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	
	const CGFloat topMargin = 20 + self.topLayoutGuide.length + self.navigationController.navigationBar.frame.size.height;
	CGSize pageSize = (self.currentOrientation & UIInterfaceOrientationMaskLandscape) ?
		CGSizeMake(screenSize.width / 3., screenSize.height - topMargin) :
		CGSizeMake(screenSize.width / 2., (screenSize.height - topMargin) / 2.);
	
	int pageOffset = page * _scrollView.frame.size.width;
	CGFloat x = (col * pageSize.width) + pageOffset;
	CGFloat y = row * pageSize.height;
	CGRect frame = CGRectMake((int)x, (int)y, pageSize.width, pageSize.height);
	
	const Class class = (countdown.type == CountdownTypeTimer) ? TimerPageView.class : CountdownPageView.class;
	PageView * view = [[class alloc] initWithFrame:CGRectZero];
	view.countdown = countdown;
	
	PageViewContainer * container = [[PageViewContainer alloc] initWithPageView:view];
	container.frame = frame;
	container.delegate = self;
	[_containers addObject:container];
	[_scrollView addSubview:container];
	
	if (animated) {
		container.alpha = 0.;
		container.transform = CGAffineTransformMakeScale(0.1, 0.1);
		[UIView animateWithDuration:0.25
						 animations:^{
							 container.alpha = 1.;
							 container.transform = CGAffineTransformIdentity;
						 }];
	}
	
	return view;
}

- (void)reloadPageAtIndex:(NSInteger)index
{
	NSDebugLog(@"Reloading page at index: %ld", (long)index);
	
	CGSize screenSize = ([UIScreen mainScreen].bounds.size);
	if /**/ (self.currentOrientation & UIInterfaceOrientationMaskLandscape && screenSize.height > screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	else if (self.currentOrientation & UIInterfaceOrientationMaskPortrait && screenSize.height < screenSize.width)
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	
	CGSize pageSize = (self.currentOrientation & UIInterfaceOrientationMaskLandscape) ?
		CGSizeMake(screenSize.width / 3., screenSize.height - self.topLayoutGuide.length) :
		CGSizeMake(screenSize.width / 2., (screenSize.height - self.topLayoutGuide.length) / 2.);
	CGRect rect = CGRectMake(0., 0., pageSize.width, pageSize.height);
	
	PageViewContainer * container = _containers[CLIP(0, index, _containers.count-1)];
	NSArray <Countdown *> * const countdowns = [Countdown allCountdowns];
	Countdown * const countdown = countdowns[CLIP(0, index, countdowns.count-1)];
	if (([container.pageView isKindOfClass:CountdownPageView.class] && countdown.type != CountdownTypeCountdown) ||
		([container.pageView isKindOfClass:TimerPageView.class] && countdown.type != CountdownTypeTimer)) {
		
		[container removeFromSuperview];
		
		const Class class = (countdown.type == CountdownTypeTimer) ? TimerPageView.class : CountdownPageView.class;
		PageView * pageView = [[class alloc] initWithFrame:CGRectZero];
		pageView.countdown = countdown;
		
		container = [[PageViewContainer alloc] initWithPageView:pageView];
		container.frame = rect;
		container.delegate = self;
		[_scrollView addSubview:container];
		_containers[index] = container;
		
	} else {
		container.pageView.countdown = countdown;
	}
}

- (void)deletePageAtIndex:(NSInteger)index animated:(NSInteger)animated
{
	[_settingsViewController dismissViewControllerAnimated:NO completion:nil];
	
	PageViewContainer * container = _containers[index];
	container.alpha = 1.;
	container.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 container.alpha = 0.;
						 container.transform = CGAffineTransformMakeScale(0.1, 0.1);
					 }
					 completion:^(BOOL finished) { [container removeFromSuperview]; }];
	
	[_containers removeObjectAtIndex:index];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.automaticallyAdjustsScrollViewInsets = NO;
	
	_currentSettingsPageIndex = -1;
	_currentOrientation = ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskLandscape;
	
	[self showNavigationBar:kDefaultNavigationBar animated:NO];
	
	NSArray * countdowns = [Countdown allCountdowns];
	_containers = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	
	int index = 0;
	for (Countdown * countdown in countdowns)
		[self createPageWithCountdown:countdown atIndex:index++ animated:NO];
	
	[self updateLayoutWithOrientation:self.currentOrientation animated:NO];
	
	_scrollView.pagingEnabled = YES;
	_scrollView.delegate = self;
	_scrollView.delaysContentTouches = NO;
	
	self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
	_pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
	_pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
	_pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1. alpha:0.3];
	_pageControl.hidesForSinglePage = YES;
	self.navigationItem.titleView = _pageControl;
	
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
													  // Invalidate the layout
													  [self invalidateLayout];
													  
													  // Scroll to last page
													  CGSize size = _scrollView.frame.size;
													  CGRect rect = CGRectMake(_pageControl.currentPage * size.width, 0., size.width, size.height);
													  [_scrollView scrollRectToVisible:rect animated:YES];
													  _pageControl.currentPage = (_pageControl.numberOfPages - 1);
												  }];
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification object:nil];
	
	// Keyboard showing/hidding notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
	[self setNeedsStatusBarAppearanceUpdate];
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

#pragma mark - Popover presentation controller delegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
	[self reloadPageAtIndex:_currentSettingsPageIndex];
	_currentSettingsPageIndex = 0;
}

#pragma mark - Page control managment

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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
