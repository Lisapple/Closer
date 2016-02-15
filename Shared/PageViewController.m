//
//  PageViewController.m
//  Closer
//
//  Created by Max on 13/02/16.
//
//

#import "PageViewController.h"
#import "CountdownPageView.h"
#import "TimerPageView.h"

@interface PageViewController ()

@end

@implementation PageViewController

- (instancetype)initWithCountdown:(Countdown *)countdown
{
	if ((self = [super init])) {
		_countdown = countdown;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	PageView * pageView = nil;
	if (_countdown.type == CountdownTypeTimer)
		pageView = [[TimerPageView alloc] initWithFrame:self.view.bounds];
	else
		pageView = [[CountdownPageView alloc] initWithFrame:self.view.bounds];
	
	pageView.countdown = self.countdown;
	[pageView update];
	pageView.subviews.lastObject.backgroundColor = [[UIColor backgroundColorForStyle:self.countdown.style] colorWithAlphaComponent:0.7];
	[self.view addSubview:pageView];
}

@end
