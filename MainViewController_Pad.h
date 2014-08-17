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

enum DeleteButtonState {
	DeleteButtonStateHidden = 0,
	DeleteButtonStateShow,
	DeleteButtonStateConfirmation
	};

@interface DeleteButton : UIButton
{
@private
    enum DeleteButtonState state;
}

@property (nonatomic, assign) enum DeleteButtonState state;

@end

@class PageView;

@interface MainViewController_Pad : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, PageViewDelegate, UIPopoverControllerDelegate>
{
	IBOutlet UIView * defaultNavigationBarView, * editNavigationBarView;
	IBOutlet UIBarButtonItem * doneButton;
	IBOutlet UIScrollView * scrollView;
	IBOutlet UIPageControl * pageControl;
	
	@private
	NSInteger currentSettingsPageIndex;
	int currentNavigationBarTag;
	NSMutableArray * pageViews;
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
- (IBAction)changePage:(id)sender;

@end
