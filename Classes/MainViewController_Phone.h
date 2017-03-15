//
//  MainViewController.h
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import Crashlytics;

#import "SettingsViewController.h"
#import "CountdownPageView.h"
#import "TimerPageView.h"

@interface MainViewController_Phone : UIViewController <SettingsViewControllerDelegate, UIScrollViewDelegate, PageViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView * scrollView;
@property (nonatomic, strong) IBOutlet UIPageControl * pageControl;
@property (nonatomic, strong) IBOutlet UIView * mainView;
@property (nonatomic, strong) IBOutlet UILabel * label;
@property (nonatomic, strong) IBOutlet UIButton * infoButton;

@property (nonatomic, strong) NSTimer * updateTimeLabelTimer, * animationDelay;

@property (nonatomic, strong) NSMutableArray <PageView *> * pages;

@property (nonatomic, strong) SettingsViewController_Phone * settingsViewController;

// Select page

- (void)selectPageWithCountdown:(Countdown *)countdown animated:(BOOL)animated;

// Current Page Index

- (NSInteger)selectedPageIndex;

// Add Page

- (void)addPageWithCountDown:(Countdown *)aCountdown;
- (void)update;
- (void)removeAllPages;

// Page and Page's Settings Selection

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;

// Update Time Labels Managment

- (void)startUpdateTimeLabels;
- (void)updateTimeLabels;
- (void)stopUpdateTimeLabels;

// Actions

- (IBAction)showSettings:(id)sender;

// Show Description Managment

//- (void)showDescriptions:(BOOL)show animated:(BOOL)animated;

// UIPageControl Managment

- (IBAction)changePage:(id)sender;

@end
