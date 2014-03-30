//
//  PageViewController.h
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FontDescription.h"

#import <QuartzCore/QuartzCore.h>

#import "PageView.h"

@class Countdown;

typedef enum {
	CountdownPageViewStyleDefault,
	CountdownPageViewStyleLCD,
	CountdownPageViewStyleBoard,
	CountdownPageViewStyleLetter,
	CountdownPageViewStyleTimes,
} CountdownPageViewStyle;

@interface CountdownPageView : PageView
{
@private
	// Portrait
	IBOutlet UIView * _contentView;
	
	IBOutlet UILabel * daysLabel, * hoursLabel, * minutesLabel, * secondsLabel;
	IBOutlet UILabel * daysDescriptionLabel, * hoursDescriptionLabel, * minutesDescriptionLabel, * secondsDescriptionLabel;
	
	IBOutlet UIButton * infoButton;
	IBOutlet UILabel * nameLabel;
	
	IBOutlet UIImageView * backgroundImageView;
	
	// Landscape
	IBOutlet UIView * _contentViewLandscape;
	
	IBOutlet UILabel * timeLabelLanscape;
	
	IBOutlet UIButton * infoButtonLandscape;
	IBOutlet UILabel * nameLabelLandscape;
	
	IBOutlet UIImageView * backgroundImageViewLandscape;
	
	UIButtonType infoButtonType;
	
	BOOL _loaded;
	
	// Accesssibility
	NSArray * accessibilityElements;
	
@public
	
	CountdownPageViewStyle style;
}

// Private
// Portrait
@property (nonatomic, strong) IBOutlet UILabel * daysLabel, * hoursLabel, * minutesLabel, * secondsLabel;
@property (nonatomic, strong) IBOutlet UILabel * daysDescriptionLabel, * hoursDescriptionLabel, * minutesDescriptionLabel, * secondsDescriptionLabel;

@property (nonatomic, strong) IBOutlet UIButton * infoButton;
@property (nonatomic, strong) IBOutlet UILabel * nameLabel;

@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageView;

@property (nonatomic, strong) NSString * backgroundImageName, * landscapeBackgroundImageName;

// Landscape

@property (nonatomic, strong) IBOutlet UILabel * timeLabelLanscape;

@property (nonatomic, strong) IBOutlet UIButton * infoButtonLandscape;
@property (nonatomic, strong) IBOutlet UILabel * nameLabelLandscape;

@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageViewLandscape;

// Public
@property (nonatomic, assign) CountdownPageViewStyle style;

- (void)showDescription:(BOOL)show animated:(BOOL)animated;
- (void)setInfoButtonType:(UIButtonType)type;

- (IBAction)showSettings:(id)sender;

@end
