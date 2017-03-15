//
//  PageViewController.h
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "FontDescription.h"

#import "PageView.h"
#import "CCLabel.h"

@class Countdown;

@interface CountdownPageView : PageView

@property (nonatomic, strong) IBOutlet CCLabel * daysLabel, * hoursLabel, * minutesLabel, * secondsLabel;
@property (nonatomic, strong) IBOutlet CCLabel * daysDescriptionLabel, * hoursDescriptionLabel, * minutesDescriptionLabel, * secondsDescriptionLabel;

@property (nonatomic, strong) IBOutlet UILabel * nameLabel;

@property (nonatomic, strong) NSString * backgroundImageName;

- (IBAction)showSettings:(id)sender;

@end
