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
	
	Class class = (_countdown.type == CountdownTypeTimer) ? TimerPageView.class : CountdownPageView.class;
	PageView * pageView = [[class alloc] initWithFrame:self.view.bounds];
	pageView.countdown = self.countdown;
	[pageView update];
	pageView.subviews.lastObject.backgroundColor = [[UIColor backgroundColorForStyle:self.countdown.style] colorWithAlphaComponent:0.7]; // @TODO: Should had a property for background view
	[self.view addSubview:pageView];
}

@end
