//
//  TimerPageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "PageView.h"

#import "TimerView.h"
#import "CCLabel.h"

@interface TimerPageView : PageView <UIGestureRecognizerDelegate>

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
