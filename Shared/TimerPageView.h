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
	
	IBOutlet UIView * _contentView;
	
	IBOutlet UILabel * timeLabel, * descriptionLabel;
	
	IBOutlet UIButton * leftButton, * _tintedInfoButton /* For iOS 6, since tint color doesn't work for info button */;
	IBOutlet UILabel * nameLabel;
	
	// Private
	NSTimeInterval remainingSeconds, duration;
	NSDate * nextEndDate;
	BOOL isPaused, isFinished;
	BOOL _loaded;
}

@property (nonatomic, strong) IBOutlet TimerView * timerView;

@property (nonatomic, strong) IBOutlet UILabel * timeLabel, * descriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton * leftButton;
@property (nonatomic, strong) IBOutlet UILabel * nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageView;

- (IBAction)showSettings:(id)sender;

- (void)pause;
- (void)start;

- (void)reload;

@end
