//
//  ViewController.h
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import UIKit;
@import QuartzCore;
@import Crashlytics;

#import "SettingsViewController.h"
#import "PageViewContainer.h"

@interface MainViewController_Pad : UIViewController <UIScrollViewDelegate, PageViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, assign) IBOutlet UIView * defaultNavigationBarView, * editNavigationBarView;
@property (nonatomic, assign) IBOutlet UIBarButtonItem * doneButton;
@property (nonatomic, assign) IBOutlet UIScrollView * scrollView;
@property (nonatomic, strong) UIPageControl * pageControl;

@property (nonatomic, assign) UIInterfaceOrientationMask currentOrientation;

@property (nonatomic, strong) SettingsViewController * settingsViewController;

- (IBAction)new:(id)sender;
- (IBAction)editAll:(id)sender;

- (IBAction)done:(id)sender;

- (IBAction)showPopover:(id)sender;
- (IBAction)close:(id)sender;

// UIPageControl Managment
- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (IBAction)changePage:(id)sender;

@end
