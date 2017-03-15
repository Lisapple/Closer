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

@property (nonatomic, strong) IBOutlet CCLabel * timeLabel;
@property (nonatomic, strong) IBOutlet UILabel * descriptionLabel;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageView;

- (IBAction)pauseButtonAction:(id)sender;

- (void)tooglePause;
- (void)reset;
- (void)reload;

@end
