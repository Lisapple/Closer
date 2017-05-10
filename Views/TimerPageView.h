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

extern NSString * const TimerDidContinueNotification;

@interface TimerPageView : PageView <UIGestureRecognizerDelegate>

- (void)tooglePause;
- (void)reset;
- (void)reload;

@end
