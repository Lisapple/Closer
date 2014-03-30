//
//  MainViewController.h
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SettingsViewController_Phone.h"
#import "CountdownPageView.h"
#import "TimerPageView.h"

@interface MainViewController_Phone : UIViewController <SettingsViewControllerDelegate, UIScrollViewDelegate, PageViewDelegate>
{
	IBOutlet UIScrollView * scrollView;
	IBOutlet UIPageControl * pageControl;
	IBOutlet UIView * mainView;
	IBOutlet UILabel * label;
	IBOutlet UIButton * infoButton;
	
	NSTimer * updateTimeLabelTimer, * animationDelay;
	
	NSMutableArray * pages;
	
	SettingsViewController_Phone * settingsViewController;
}

@property (nonatomic, strong) IBOutlet UIScrollView * scrollView;
@property (nonatomic, strong) IBOutlet UIPageControl * pageControl;
@property (nonatomic, strong) IBOutlet UIView * mainView;
@property (nonatomic, strong) IBOutlet UILabel * label;
@property (nonatomic, strong) IBOutlet UIButton * infoButton;

@property (nonatomic, strong) NSTimer * updateTimeLabelTimer, * animationDelay;

@property (nonatomic, strong) NSMutableArray * pages;

#pragma mark Current Page Index

- (NSInteger)selectedPageIndex;

#pragma mark Page Memory Managing

- (void)loadPageAtIndex:(NSInteger)pageIndex;
- (void)loadAllPages;
- (void)unloadPageAtIndex:(NSInteger)pageIndex;
- (void)unloadHiddenPages;

#pragma mark Add Page

- (void)addPageWithCountDown:(Countdown *)aCountdown;
- (void)update;
- (void)removeAllPages;

#pragma mark Page and Page's Settings Selection

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (void)showSettingsForPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;

#pragma mark Update Time Labels Managment

- (void)startUpdateTimeLabels;
- (void)updateTimeLabels;
- (void)stopUpdateTimeLabels;

#pragma mark Go To Settings

- (IBAction)showSettings:(id)sender;

#pragma mark Show Description Managment

- (void)showDescriptions:(BOOL)show animated:(BOOL)animated;

#pragma mark UIPageControl Managment

- (IBAction)changePage:(id)sender;

@end
