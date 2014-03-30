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

#import "Countdown.h"

#import "NetworkStatus.h"

#import "UIColor+addition.h"
#import "NSObject+additions.h"

@implementation DeleteButton

@synthesize state;

- (void)setState:(enum DeleteButtonState)theState
{
	if (state == DeleteButtonStateShow &&
		theState == DeleteButtonStateConfirmation) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 self.transform = CGAffineTransformMakeRotation(M_PI_2);
						 }];
	} else if (state == DeleteButtonStateConfirmation &&
			   theState == DeleteButtonStateShow) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 self.transform = CGAffineTransformIdentity;
						 }];
	}
	
	state = theState;
}

@end

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

#define kImportAlertTag 1234

/*** Views Structure ***
 * "scrollView"
 * {
 **	- containerView
 ** {
 *** - pageView (tag = 100)
 *** {
 **** - DeleteButton (tag = 1001, the red circle with white border, above the "confirmationView")
 **** - confirmationView (tag = 1002)
 **** {
 ***** - imageView (the background of the confirmation button)
 ***** - confirmationButton (the "Delete" button)
 **** }
 *** }
 *** - secondView (tag = 200, for settings)
 **	}
 * }
 */

enum tags {
	PageViewTag = 100,
	DeleteButtonTag = 1001,
	ConfirmationViewTag = 1002,
	
	SecondViewTag = 200
};


@implementation MainViewController_Pad

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)showNavigationBar:(NSInteger)navigationBarTag
{
	[self showNavigationBar:navigationBarTag animated:YES];
}

- (void)showNavigationBar:(NSInteger)navigationBarTag animated:(BOOL)animated
{
	if (navigationBarTag == kEditNavigationBar) {
		CGRect frame = editNavigationBarView.frame;
		frame.size.width = scrollView.frame.size.width;
		editNavigationBarView.frame = frame;
		
		if ([doneButton respondsToSelector:@selector(setTintColor:)])
			doneButton.tintColor = [UIColor doneButtonColor];
		
		editNavigationBarView.alpha = 0.;
		[self.view addSubview:editNavigationBarView];
		[UIView animateWithDuration:(animated)? 0.25 : 0.
						 animations:^{ editNavigationBarView.alpha = 1.; }
						 completion:^(BOOL finished) { [defaultNavigationBarView removeFromSuperview]; }];
	} else {
		CGRect frame = editNavigationBarView.frame;
		frame.size.width = scrollView.frame.size.width;
		defaultNavigationBarView.frame = frame;
		
		defaultNavigationBarView.alpha = 0.;
		[self.view addSubview:defaultNavigationBarView];
		[UIView animateWithDuration:(animated)? 0.25 : 0.
						 animations:^{ defaultNavigationBarView.alpha = 1.; }
						 completion:^(BOOL finished) { [editNavigationBarView removeFromSuperview]; }];
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
			Countdown * countdown = (Countdown *)[countdowns objectAtIndex:i];
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
	__block Countdown * aCountDown = [[Countdown alloc] init];
	aCountDown.name = [self proposedNameForType:CountdownTypeDefault];
	
	int numberOfRows = 2;
	int numberOfColumns = 2;
	NSInteger numberOfPages = ceil((pageViews.count + 1) / (float)(numberOfRows * numberOfColumns));
	CGRect rect = scrollView.bounds;
	rect.origin.x = (numberOfPages - 1) * rect.size.width;
	
	double delayInSeconds = 0.;
	if (scrollView.contentOffset.x < rect.origin.x) {// If the scrollView have to scroll, "pop" the new countdown after a delay
		
		/* Strech the scrollView to add a last page */
		scrollView.contentSize = CGSizeMake(numberOfPages * scrollView.frame.size.width, scrollView.frame.size.height);
		
		/* Scroll to the countdown new position */
		[scrollView setContentOffset:rect.origin
							animated:YES];
		
		pageControl.numberOfPages = numberOfPages;
		pageControl.currentPage = (numberOfPages - 1);
		
		delayInSeconds = 0.5;
	}
	
	[NSObject performBlock:^{
		
		PageView * pageView = [self createPageWithCountdown:aCountDown
													atIndex:pageViews.count // After the last pageView ("pageViews.count - 1 + 1")
												   animated:YES];
		if (editing)
			[self showDeleteButtonOnPage:pageView];
		
		[NSObject performBlock:^{ [Countdown addCountdown:aCountDown]; }
					afterDelay:0.5];
	}
				afterDelay:delayInSeconds];
	
#if 0
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		PageView * pageView = [self createPageWithCountdown:aCountDown
													atIndex:([Countdown numberOfCountdowns] - 1)
												   animated:YES];
		
		if (editing)
			[self showDeleteButtonOnPage:pageView];
		
		/* The layout is updated after the synchronisation of countdowns */
		[Countdown synchronize];
	});
#endif
}

- (IBAction)editAll:(id)sender
{
	if (currentNavigationBarTag != kEditNavigationBar) {
		[self showNavigationBar:kEditNavigationBar animated:YES];
		[self handleLongTapFrom:nil];
	}
	
	editing = YES;
}

- (IBAction)done:(id)sender
{
	if (currentNavigationBarTag == kEditNavigationBar) {
		[self showNavigationBar:kDefaultNavigationBar animated:YES];
	}
	
	for (CountdownPageView * pageView in pageViews) {
		
		/* Remove the Delete Button */
		[[pageView viewWithTag:DeleteButtonTag] removeFromSuperview];
		
		/* Remove the confirmation view */
		[[pageView viewWithTag:ConfirmationViewTag] removeFromSuperview];
	}
	
	editing = NO;
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	if (importActionSheetShowing) {
		[importActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
		importActionSheetShowing = NO;
		[self import:nil];
	}
}

- (IBAction)import:(id)sender
{
	if (!importActionSheetShowing) {
		BOOL isConnected = [NetworkStatus isConnected];
		importActionSheet = [[UIActionSheet alloc] initWithTitle:nil
														delegate:self
											   cancelButtonTitle:nil
										  destructiveButtonTitle:nil
											   otherButtonTitles:NSLocalizedString(@"Import from Calendar", nil), nil];
		if (isConnected)
			[importActionSheet addButtonWithTitle:NSLocalizedString(@"Import with Passwords", nil)];
		
		importActionSheet.tag = kImportAlertTag;
		[importActionSheet showFromBarButtonItem:(UIBarButtonItem *)sender
										animated:NO];
		
		importActionSheetShowing = YES;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kImportAlertTag) {// Import action sheet
		if (buttonIndex == 0) {
			ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] init];
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromCalendarViewController];
			navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navigationController
									animated:YES];
		} if (buttonIndex == 1) {
			
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
			} else {
				ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
				UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
				navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
				navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
				[self presentModalViewController:navigationController
										animated:YES];
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
				/*
				 case 2:// Send me an e-mail
				 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://4automator@googlemail.com"]];
				 break;
				 */
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
	if (actionSheet.tag == kImportAlertTag)
		importActionSheetShowing = NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	ImportFromWebsiteViewController_Pad * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Pad alloc] init];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
	navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:navigationController
							animated:YES];
}

- (IBAction)export:(id)sender
{
	ExportViewController * exportViewController = [[ExportViewController alloc] init];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:exportViewController];
	navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:navigationController
							animated:YES];
}

- (void)showSettingsForPageAtIndex:(NSInteger)index
{
	/* Hide the delete confirmation */
	[self hideDeleteConfirmationOnPage:currentPageWithConfirmation];
	
	/* Close the active settings */
	[self closeActiveSettings];
	
	UIView * containerView = [containerViews objectAtIndex:index];
	CGRect frame = containerView.bounds;
	
	__block PageView * pageView = [pageViews objectAtIndex:index];
	
	SettingsViewController_Pad * settingsViewController = [[SettingsViewController_Pad alloc] init];
	settingsViewController.countdown = [Countdown countdownAtIndex:index];
	
	settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	
	UIView * secondView = [[UIView alloc] initWithFrame:frame];
	
	frame = CGRectMake(20., 8., 320., 402.);
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		frame.size = CGSizeMake(450., 290.);
	}
	
	settingsNavigationController.view.frame = frame;
	settingsNavigationController.view.clipsToBounds = YES;
	[secondView addSubview:settingsNavigationController.view];
	
	UIImageView * imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"popover"] stretchableImageWithLeftCapWidth:50
																													  topCapHeight:50]];
	imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	imageView.frame = secondView.bounds;
	[secondView addSubview:imageView];
	
	secondView.tag = SecondViewTag;
	
	[containerView addSubview:secondView];
	
	[UIView transitionWithView:containerView
					  duration:0.5
					   options:UIViewAnimationOptionTransitionFlipFromRight
					animations:^{
						pageView.hidden = YES;
					}
					completion:NULL];
	
	currentSettingsPageIndex = index;
}

- (IBAction)showPopover:(id)sender
{
	[self showSettingsForPageAtIndex:1];
}

- (void)closeSettingsForPageAtIndex:(NSInteger)index
{
	settingsNavigationController = nil;
	
	UIView * containerView = [containerViews objectAtIndex:index];
	
	PageView * pageView = [pageViews objectAtIndex:index];
	pageView.countdown = [Countdown countdownAtIndex:index];
	
	[UIView transitionWithView:containerView
					  duration:0.5
					   options:UIViewAnimationOptionTransitionFlipFromLeft
					animations:^{
						UIView * secondView = [containerView viewWithTag:SecondViewTag];
						[secondView removeFromSuperview];
						pageView.hidden = NO;
					}
					completion:NULL];
	currentSettingsPageIndex = -1;
}

- (void)closeActiveSettings
{
	if (currentSettingsPageIndex >= 0)
		[self closeSettingsForPageAtIndex:currentSettingsPageIndex];
}

- (IBAction)close:(id)sender
{
	[self closeSettingsForPageAtIndex:1];
}

- (IBAction)showSettings:(id)sender
{
	UIButton * button = sender;
	PageView * page = (PageView *)[[button superview] superview];
	if ([pageViews indexOfObject:page] != NSNotFound)
		[self showSettingsForPageAtIndex:[pageViews indexOfObject:page]];
}

- (IBAction)showInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © 2013, Lis@cintosh\n", nil), [infoDictionary objectForKey:@"CFBundleShortVersionString"]];
	
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:
								   NSLocalizedString(@"Show Countdowns Online", nil),
								   NSLocalizedString(@"Feedback & Support", nil),
								   /*NSLocalizedString(@"Send me an e-mail", nil),*/
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

#pragma mark - Delete Management

- (void)deleteCountdown:(id)sender
{
	PageView * pageView = (PageView *)[[(UIButton *)sender superview] superview];
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

- (void)showDeletingConfirmation:(id)sender
{
	DeleteButton * button = (DeleteButton *)sender;
	
	/* Remove the confirmation if it's already shown */
	if (button.state == DeleteButtonStateConfirmation) {
		[self cancelDeletingConfirmation:sender];
		return;
	}
	
	/* Hide the last confirmation shown */
	[self hideDeleteConfirmationOnPage:currentPageWithConfirmation];
	
	button.state = DeleteButtonStateConfirmation;
	
	CGRect frame = CGRectMake(-36., 4., 110., 40);
	UIView * view = [[UIView alloc] initWithFrame:frame];
	view.tag = ConfirmationViewTag;
	
	frame.origin = CGPointZero;
	UIImageView * imageView = [[UIImageView alloc] initWithFrame:frame];
	imageView.image = [[UIImage imageNamed:@"delete-view"] stretchableImageWithLeftCapWidth:12 topCapHeight:20];
	[view addSubview:imageView];
	
	view.layer.anchorPoint = CGPointMake(0.15, 0.5);
	view.transform = CGAffineTransformMakeRotation(-M_PI_2);
	
	view.alpha = 0.;
	
	frame = CGRectMake(35., 5., 67., 27.);
	UIButton * confirmationButton = [UIButton buttonWithType:UIButtonTypeCustom];
	confirmationButton.frame = frame;
	
	//confirmationButton.exclusiveTouch = YES;
	
	confirmationButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.];
	confirmationButton.titleLabel.shadowOffset = CGSizeMake(0., -1);
	
	[confirmationButton setBackgroundImage:[[UIImage imageNamed:@"delete-confirmation-button"] stretchableImageWithLeftCapWidth:6 topCapHeight:14]
								  forState:UIControlStateNormal];
	
	[confirmationButton setTitle:NSLocalizedString(@"Delete", nil)
						forState:UIControlStateNormal];
	
	[confirmationButton addTarget:self
						   action:@selector(deleteCountdown:)
				 forControlEvents:UIControlEventTouchUpInside];
	
	[view addSubview:confirmationButton];
	
	PageView * pageView = (PageView *)button.superview;
	[pageView insertSubview:view belowSubview:button];// Insert the delete view just above the delete badge
	
	[UIView animateWithDuration:0.25
					 animations:^{
						 view.alpha = 1.;
						 view.transform = CGAffineTransformIdentity;
					 }
					 completion:^(BOOL finished) {  }];
	
	currentPageWithConfirmation = pageView;
}

- (void)cancelDeletingConfirmation:(id)sender
{
	DeleteButton * button = (DeleteButton *)sender;
	if (button.state == DeleteButtonStateConfirmation) {
		button.state = DeleteButtonStateShow;
		
		PageView * pageView = (PageView *)button.superview;
		[self hideDeleteConfirmationOnPage:pageView];
	}
}

- (void)handleLongTapFrom:(UIGestureRecognizer *)recognizer
{
	for (PageView * pageView in pageViews) {
		[self showDeleteButtonOnPage:pageView];
	}
}

- (void)showDeleteButtonOnPage:(PageView *)pageView
{
	DeleteButton * button = [DeleteButton buttonWithType:UIButtonTypeCustom];
	button.frame = CGRectMake(8., 8., 28., 28.);
	[button setImage:[UIImage imageNamed:@"delete-badge"]
			forState:UIControlStateNormal];
	[button addTarget:self
			   action:@selector(showDeletingConfirmation:)
	 forControlEvents:UIControlEventTouchUpInside];
	
	button.state = DeleteButtonStateShow;
	button.tag = DeleteButtonTag;
	
	[pageView addSubview:button];
	
#if 0
	/* Remove the long press recognizer from view to not be catched by the delete button */
	NSArray * recognizers = [[pageView gestureRecognizers] copy];
	for (UIGestureRecognizer * aRecognizer in recognizers) {
		if ([aRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
			[pageView removeGestureRecognizer:aRecognizer];
	}
	[recognizers release];
#endif
}

- (void)hideDeleteConfirmationOnPage:(PageView *)pageView
{
	if (pageView) {
		/* Rollback the delete button to the initial position */
		DeleteButton * deleteButton = (DeleteButton *)[pageView viewWithTag:DeleteButtonTag];
		deleteButton.state = DeleteButtonStateShow;
		
		/* Remove the confirmation view */
		UIView * confirmationView = [pageView viewWithTag:ConfirmationViewTag];
		[UIView animateWithDuration:0.25
						 animations:^{
							 confirmationView.alpha = 0.;
							 confirmationView.transform = CGAffineTransformMakeRotation(-M_PI_2);
						 }
						 completion:^(BOOL finished) { [confirmationView removeFromSuperview]; }];
	}
}

- (void)update
{
	for (PageView * pageView in pageViews) {
		[pageView update];
	}
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
	if (countdowns.count > containerViews.count) {// If we have countdown to add
		
		NSInteger count = containerViews.count;
		NSArray * newCountdowns = [countdowns subarrayWithRange:NSMakeRange(containerViews.count, (countdowns.count - containerViews.count))];
		for (Countdown * countdown in newCountdowns) {
			PageView * pageView = [self createPageWithCountdown:countdown
														atIndex:count
													   animated:animated];
			
			if (editing) [self showDeleteButtonOnPage:pageView];
			
			count++;
		}
		
	} else if (countdowns.count < containerViews.count) {// If we have countdowns to remove
		
		NSRange range = NSMakeRange(countdowns.count - 1, (containerViews.count - countdowns.count));
		[containerViews removeObjectsInRange:range];
		[pageViews removeObjectsInRange:range];
	}
	
	/* Reload remaining PageView*/
	for (int i = 0; i < countdowns.count; i++) {
		[self reloadPageViewAtIndex:i];
	}
	
#if 0
	NSInteger index = 0;
	for (Countdown * countdown in countdowns) {
		
		PageView * pageView = pageViews[index];
		/* If the type of page doesn't match with the type of countdown/timer, recreate a new page with the correct type */
		if ((countdown.type == CountdownTypeTimer && [pageView isKindOfClass:[CountdownPageView class]])
			|| (countdown.type == CountdownTypeDefault && [pageView isKindOfClass:[TimerPageView class]])) {
			
			PageView * pageView = [self createPageWithCountdown:countdown
														atIndex:index
													   animated:NO];
			[pageViews replaceObjectAtIndex:index withObject:pageView];
			
			[self reloadPageViewAtIndex:index];
		}
		//pageView.countdown = countdown;
		index++;
	}
#endif
	
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
	
	/* the size of the container view */
	CGSize size = CGSizeMake(360., 430.);
	if (UIInterfaceOrientationIsLandscape(orientation))
		size = CGSizeMake(490., 320.);
	
	CGSize pageSize = CGSizeMake(300., 423.);
	if (UIInterfaceOrientationIsLandscape(orientation))
		pageSize = CGSizeMake(470., 280.);
	
	CGRect frame = CGRectMake(0., 0., scrollView.frame.size.width, scrollView.frame.size.height);
	
	CGFloat leftMargin = (int)((frame.size.width - numberOfColumns * size.width) / (numberOfColumns + 1));
	CGFloat topMargin = (int)((frame.size.height - numberOfRows * size.height) / (numberOfRows + 1));
	
	NSInteger numberOfCountdowns = [Countdown numberOfCountdowns];
	int numberOfPage = ceil(numberOfCountdowns / (float)(numberOfRows * numberOfColumns));
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	int i = 0;
	for (UIView * containerView in containerViews) {
		
		int index = i % (numberOfRows * numberOfColumns);
		int row = index / numberOfRows;
		int col = index % numberOfRows;
		int page = i / (numberOfRows * numberOfColumns);
		
		int pageOffset = page * scrollView.frame.size.width;
		
		CGFloat x = leftMargin + (col * (size.width + leftMargin)) + frame.origin.x + pageOffset;
		CGFloat y = topMargin + (row * (size.height + topMargin)) + frame.origin.y;
		
		CGRect rect = CGRectMake((int)x, (int)y, size.width, size.height);
		[UIView animateWithDuration:(animated)? 0.25 : 0.
						 animations:^{
							 containerView.frame = rect;
						 }
						 completion:NULL];
		
		x = (size.width - pageSize.width) / 2. - 8.;
		y = (size.height - pageSize.height) / 2.;
		PageView * pageView = [pageViews objectAtIndex:i];
		pageView.frame = CGRectMake((int)x, (int)y, pageSize.width, pageSize.height);
		
		if (i == currentSettingsPageIndex) {
			// Change the layout of the page that shows settings
			
			CGRect containerFrame = CGRectMake(0., 0., size.width, size.height);
			
			CGRect innerContainerFrame = CGRectMake(20., 8., 320., 402.);
			if (UIInterfaceOrientationIsLandscape(orientation))
				innerContainerFrame.size = CGSizeMake(450., 290.);
			
			UIView * secondView = [containerView viewWithTag:SecondViewTag];
			secondView.frame = containerFrame;
			
			settingsNavigationController.view.frame = innerContainerFrame;
		}
		
		i++;
	}
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	// @TODO: animate when the number of pages change
	scrollView.contentSize = CGSizeMake(numberOfPage * scrollView.frame.size.width, scrollView.frame.size.height);
	
	size = scrollView.frame.size;
	CGRect rect = CGRectMake(pageControl.currentPage * size.width, 0., size.width, size.height);
	[scrollView scrollRectToVisible:rect animated:NO];
	
	pageControl.numberOfPages = numberOfPage;
}

- (PageView *)createPageWithCountdown:(Countdown *)countdown atIndex:(NSInteger)index animated:(BOOL)animated
{
	int numberOfRows = 2;
	int numberOfColumns = 2;
	
	/* the size of the container view */
	CGSize size = CGSizeMake(360., 430.);
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		size = CGSizeMake(490., 320.);
	
	CGSize pageSize = CGSizeMake(300., 423.);
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		pageSize = CGSizeMake(470., 280.);
	
	CGFloat x = (size.width - pageSize.width) / 2. - 8.;
	CGFloat y = (size.height - pageSize.height) / 2.;
	CGRect rect = CGRectMake((int)x, (int)y, pageSize.width, pageSize.height);
	PageView * view = nil;
	if (countdown.type == CountdownTypeTimer) {
		view = [[TimerPageView alloc] initWithFrame:rect];
	} else {
		view = [[CountdownPageView alloc] initWithFrame:rect];
	}
	
	view.countdown = countdown;
	view.orientation = self.interfaceOrientation;
	view.tag = PageViewTag;
	view.delegate = self;
	
	[pageViews addObject:view];
	
	CGRect frame = CGRectMake(0., 0., scrollView.frame.size.width, scrollView.frame.size.height);
	CGFloat leftMargin = (int)((frame.size.width - numberOfColumns * size.width) / (numberOfColumns + 1));
	CGFloat topMargin = (int)((frame.size.height - numberOfRows * size.height) / (numberOfRows + 1));
	
	int i = index % (numberOfRows * numberOfColumns);
	int row = i / numberOfRows;
	int col = i % numberOfRows;
	int page = index / (numberOfRows * numberOfColumns);
	
	int pageOffset = page * scrollView.frame.size.width;
	
	x = leftMargin + (col * (size.width + leftMargin)) + frame.origin.x + pageOffset;
	y = topMargin + (row * (size.height + topMargin)) + frame.origin.y;
	rect = CGRectMake((int)x, (int)y, size.width, size.height);
	UIView * containerView = [[UIView alloc] initWithFrame:rect];
	
	[containerView addSubview:view];
	
	if (animated) {
		containerView.alpha = 0.;
		containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	}
	
	[containerViews addObject:containerView];
	[scrollView addSubview:containerView];
	
	if (animated) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 containerView.alpha = 1.;
							 containerView.transform = CGAffineTransformIdentity;
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
	if (([pageViews[index] isKindOfClass:[CountdownPageView class]] && countdown.type != CountdownTypeDefault)
		|| ([pageViews[index] isKindOfClass:[TimerPageView class]] && countdown.type != CountdownTypeTimer)) {
		
		NSDebugLog(@"Reloading page at index: %d", index);
		
		/* the size of the container view */
		CGSize size = CGSizeMake(360., 430.);
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
			size = CGSizeMake(490., 320.);
		
		CGSize pageSize = CGSizeMake(300., 423.);
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
			pageSize = CGSizeMake(470., 280.);
		
		/*
		 CGRect rect = CGRectMake(0., 0., size.width, size.height);
		 UIView * containerView = [[UIView alloc] initWithFrame:rect];
		 */
		
		CGFloat x = (size.width - pageSize.width) / 2.;
		CGFloat y = (size.height - pageSize.height) / 2.;
		CGRect rect = CGRectMake((int)x, (int)y, pageSize.width, pageSize.height);
		
		PageView * pageView = nil;
		if (countdown.type == CountdownTypeTimer) {
			pageView = [[TimerPageView alloc] initWithFrame:rect];
		} else {
			pageView = [[CountdownPageView alloc] initWithFrame:rect];
		}
		
		pageView.countdown = countdown;
		pageView.orientation = self.interfaceOrientation;
		pageView.tag = PageViewTag;
		pageView.delegate = self;
		
		[pageViews[index] removeFromSuperview];
		[pageViews removeObjectAtIndex:index];
		[pageViews insertObject:pageView atIndex:index];
		
		UIView * containerView = containerViews[index];
		//NSInteger index = [containerView.subviews indexOfObject:[containerView viewWithTag:PageViewTag]];
		//[[containerView viewWithTag:PageViewTag] removeFromSuperview];
		
		
		[containerView insertSubview:pageView atIndex:index];
		
		/* Show the new container view only if the page is not showing settings */
		pageView.hidden = (index == currentSettingsPageIndex);
	}
}

- (void)deletePageViewAtIndex:(NSInteger)index animated:(NSInteger)animated
{
	UIView * containerView = [containerViews objectAtIndex:index];
	containerView.alpha = 1.;
	containerView.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 containerView.alpha = 0.;
						 containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					 }
					 completion:^(BOOL finished) { [containerView removeFromSuperview]; }];
	
	[pageViews removeObjectAtIndex:index];
	[containerViews removeObjectAtIndex:index];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	currentSettingsPageIndex = -1;
	
	[self showNavigationBar:kDefaultNavigationBar animated:NO];
	
	// landscape: 470 x 280
	// portrait: 300 x 423
	
	NSArray * countdowns = [Countdown allCountdowns];
	pageViews = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	containerViews = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	
	int index = 0;
	for (Countdown * countdown in countdowns) {
		PageView * pageView = [self createPageWithCountdown:countdown
													atIndex:index
												   animated:NO];
		if (editing) [self showDeleteButtonOnPage:pageView];
	}
	
	[self updateLayoutWithOrientation:self.interfaceOrientation animated:NO];
	
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	
	pageControl.autoresizingMask |= UIViewAutoresizingFlexibleHeight;// Add flexible height (Unavailable from IB)
	
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);// Run event handler on the default global queue
	dispatch_time_t now = dispatch_walltime(DISPATCH_TIME_NOW, 0);
	dispatch_source_set_timer(timer, now, 1000 * USEC_PER_SEC, 5000ull);// Fire timer one time a second, with 5 ms delay, "in case the system wants to align it with other events to minimize power consumption"
	dispatch_source_set_event_handler(timer, ^{
		[self update];
	});
	dispatch_resume(timer);
	
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
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self updateLayoutWithOrientation:self.interfaceOrientation animated:animated];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	if (currentSettingsPageIndex % 4 >= 2) { // If the index of the page is >= 2, the countdown is on the bottom line
		CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		[UIView animateWithDuration:duration
						 animations:^{
							 CGRect frame = scrollView.frame;
							 CGFloat height = MIN(keyboardSize.height, keyboardSize.width);// Get the real size from that the keyboard frame doesn't change depending of the rotation of the screen; the smaller value is the real height
							 frame.origin.y = 44. + 40. /* 40px margin*/ - height;
							 scrollView.frame = frame;
						 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	[UIView animateWithDuration:0.25
					 animations:^{
						 CGRect frame = scrollView.frame;
						 frame.origin.y = 44.;
						 scrollView.frame = frame;
					 }];
}

#pragma mark - UIPageControl Managment
- (IBAction)changePage:(id)sender
{
	CGPoint contentOffset = CGPointMake(scrollView.frame.size.width * pageControl.currentPage, 0.);
	[scrollView setContentOffset:contentOffset animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*
 - (void)viewWillAppear:(BOOL)animated
 {
 [super viewWillAppear:animated];
 }
 
 - (void)viewDidAppear:(BOOL)animated
 {
 [super viewDidAppear:animated];
 }
 
 - (void)viewWillDisappear:(BOOL)animated
 {
 [super viewWillDisappear:animated];
 }
 
 - (void)viewDidDisappear:(BOOL)animated
 {
 [super viewDidDisappear:animated];
 }
 */

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	/* Hide the delete confirmation opened when the scroll starts */
	if (currentPageWithConfirmation) {
		[self hideDeleteConfirmationOnPage:currentPageWithConfirmation];
		currentPageWithConfirmation = nil;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	pageControl.currentPage = floor(scrollView.contentOffset.x / scrollView.frame.size.width);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

/*
 - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
 {
 [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
 }
 
 - (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
 {
 [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
 }
 */

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	UIInterfaceOrientation orientation = self.interfaceOrientation;
	for (CountdownPageView * pageView in pageViews) {
		pageView.orientation = orientation;
	}
	
#if 0
	if (settingsNavigationController) {
		/*
		 CGRect frame = CGRectMake(20., 8., 320., 402.);
		 if (UIInterfaceOrientationIsLandscape(orientation)) {
		 frame.size = CGSizeMake(450., 290.);
		 }
		 */
		
		//settingsNavigationController.view.frame = frame;
		
		UIView * secondView = [[containerViews objectAtIndex:currentSettingsPageIndex] viewWithTag:SecondViewTag];
		CGRect frame = secondView.frame;
		
		frame.size = CGSizeMake(300., 423.);
		if (UIInterfaceOrientationIsLandscape(orientation))
			frame.size = CGSizeMake(470., 280.);
		
		secondView.frame = frame;
	}
#endif
	
	[self updateLayoutWithOrientation:orientation animated:NO];
}

@end
