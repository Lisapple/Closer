//
//  ViewController.h
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "PageView.h"

@class PageView;

@interface MainViewController_Pad : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, PageViewDelegate, UIPopoverControllerDelegate>
{
	IBOutlet UIView * defaultNavigationBarView, * editNavigationBarView;
	IBOutlet UIBarButtonItem * doneButton;
	IBOutlet UIScrollView * scrollView;
	IBOutlet UIPageControl * pageControl;
	
	@private
	NSInteger currentSettingsPageIndex;
	NSInteger currentNavigationBarTag;
	NSMutableArray <PageView *> * pageViews;
	PageView * currentPageWithConfirmation;
	
	BOOL shareActionSheetShowing;
	UIActionSheet * shareActionSheet;
	
	UIPopoverController * popover, * editPopover;
}

- (IBAction)new:(id)sender;
- (IBAction)editAll:(id)sender;

- (IBAction)done:(id)sender;

- (IBAction)showPopover:(id)sender;
- (IBAction)close:(id)sender;

#pragma mark UIPageControl Managment
- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (IBAction)changePage:(id)sender;

@end
