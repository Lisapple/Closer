//
//  TimerPageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import <UIKit/UIKit.h>

#import "PageView.h"

#import "TimerView.h"

@interface TimerPageView : PageView
{
	IBOutlet TimerView * timerView;
	
	// Portrait
	IBOutlet UIView * _contentView;
	
	IBOutlet UILabel * timeLabel, * descriptionLabel;
	
	/*
	IBOutlet UILabel * daysLabel, * hoursLabel, * minutesLabel, * secondsLabel;
	IBOutlet UILabel * daysDescriptionLabel, * hoursDescriptionLabel, * minutesDescriptionLabel, * secondsDescriptionLabel;
	 */
	
	IBOutlet UIButton * leftButton;
	
	IBOutlet UILabel * nameLabel;
	
	IBOutlet UIImageView * backgroundImageView;
	
	// Landscape
	IBOutlet UIView * _contentViewLandscape;
	
	IBOutlet UILabel * timeLabelLanscape, * descriptionLabelLandscape;
	
	IBOutlet UIButton * leftButtonLandscape;
	
	IBOutlet UILabel * nameLabelLandscape;
	
	IBOutlet UIImageView * backgroundImageViewLandscape;
	
	// Private
	NSTimeInterval remainingSeconds, duration;
	NSDate * nextEndDate;
	BOOL isPaused, isFinished;
	BOOL _loaded;
}

@property (nonatomic, strong) IBOutlet TimerView * timerView;

// Portrait
@property (nonatomic, strong) IBOutlet UILabel * timeLabel, * descriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton * leftButton;
@property (nonatomic, strong) IBOutlet UILabel * nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageView;
@property (nonatomic, strong) IBOutlet UIButton * infoButton;

// Landscape
@property (nonatomic, strong) IBOutlet UILabel * timeLabelLanscape, * descriptionLabelLandscape;
@property (nonatomic, strong) IBOutlet UIButton * leftButtonLandscape;
@property (nonatomic, strong) IBOutlet UILabel * nameLabelLandscape;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageViewLandscape;
@property (nonatomic, strong) IBOutlet UIButton * infoButtonLandscape;

- (IBAction)showSettings:(id)sender;

- (void)pause;
- (void)start;

- (void)reload;

@end
