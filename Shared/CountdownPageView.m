//
//  PageViewController.m
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CountdownPageView.h"

#import "UIView+addition.h"
#import "Countdown+addition.h"

@interface PageView ()

- (void)handleDoubleTap;

@end

@interface CountdownPageView ()

@property (nonatomic, assign) IBOutlet UIView * contentView;
@property (nonatomic, assign) BOOL idleTimerDisabled;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * verticallyCenterConstraint;

@property (nonatomic, strong) IBOutlet CCLabel * daysLabel, * hoursLabel, * minutesLabel, * secondsLabel;
@property (nonatomic, strong) IBOutlet CCLabel * daysDescriptionLabel, * hoursDescriptionLabel, * minutesDescriptionLabel, * secondsDescriptionLabel;

@end

@implementation CountdownPageView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		UINib * nib = [UINib nibWithNibName:@"CountdownPageView" bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self addSubview:_contentView];
		
		const CGFloat offset = 20.;
		const ParallaxAxis axis = (ParallaxAxisVertical | ParallaxAxisHorizontal);
		NSArray <UILabel *> * labels = @[ _daysLabel, _hoursLabel, _minutesLabel, _secondsLabel,
										  _daysDescriptionLabel, _hoursDescriptionLabel,
										  _minutesDescriptionLabel, _secondsDescriptionLabel ];
		for (UILabel * label in labels)
			[label addParallaxEffect:axis offset:offset];
		
		self.contentView.hidden = YES;
		
		UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
		gesture.numberOfTapsRequired = 2;
		[self.contentView addGestureRecognizer:gesture];
		
		_idleTimerDisabled = NO;
	}
	
	return self;
}

- (NSString *)padValue:(NSUInteger)value
{
	return [self formatValue:value addPadding:YES];
}

- (NSString *)formatValue:(NSUInteger)value addPadding:(BOOL)addZero
{
	return [NSString stringWithFormat:(addZero) ? @"%02ld" : @"%ld", (long)value];
}

- (void)styleDidChange:(CountdownStyle)style
{
	_contentView.backgroundColor = [[UIColor backgroundColorForStyle:style] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForStyle:style]];
}

- (void)setTextColor:(UIColor *)textColor
{
	NSArray <UILabel *> * const labels = @[ _daysLabel, _hoursLabel, _minutesLabel, _secondsLabel,
											_daysDescriptionLabel, _hoursDescriptionLabel,
											_minutesDescriptionLabel, _secondsDescriptionLabel ];
	for (UILabel * label in labels)
		label.textColor = textColor;
}

- (void)setCountdown:(Countdown *)aCountdown
{
	Countdown * oldCountdown = super.countdown;
	super.countdown = aCountdown;
	
	if (oldCountdown != nil)
		[self update];
	
	[self setNeedsUpdateStyle];
}

- (void)viewWillShow:(BOOL)animated
{
	[super viewWillShow:animated];
	
	if (ABS(self.countdown.endDate.timeIntervalSinceNow) <= self.minDurationBeforeIdle && !_idleTimerDisabled) {
		[[UIApplication sharedApplication] disableIdleTimer];
		_idleTimerDisabled = YES;
	}
}

- (void)viewDidHide:(BOOL)animated
{
	[super viewDidHide:animated];
	
	if (_idleTimerDisabled) {
		[[UIApplication sharedApplication] enableIdleTimer];
		_idleTimerDisabled = NO;
	}
}

- (void)update
{
	NSDate * date = self.countdown.endDate;
	NSTimeInterval timeInterval = MAX(0, date.timeIntervalSinceNow);
	
	NSUInteger days = timeInterval / (24. * 60. * 60.);
	timeInterval -= (days * 24 * 60 * 60);
	
	NSUInteger hours = timeInterval / (60. * 60.);
	timeInterval -= (hours * 60 * 60);
	
	NSUInteger minutes = timeInterval / 60.;
	timeInterval -= (minutes * 60);
	
	NSUInteger seconds = timeInterval;
	
	_daysLabel.hidden = (days == 0);
	_daysDescriptionLabel.hidden = (days == 0);
	_verticallyCenterConstraint.constant = (days == 0) ? (-self.frame.size.height * 0.1) : -20;
	
	BOOL animated = !(_contentView.hidden);
	
	if (days > 0)
		[_daysLabel setText:[self formatValue:days addPadding:NO] animated:animated];
	
	[_hoursLabel   setText:[self padValue:hours]   animated:animated];
	[_minutesLabel setText:[self padValue:minutes] animated:animated];
	[_secondsLabel setText:[self padValue:seconds] animated:animated];
	
	[_daysDescriptionLabel setText:(days > 1)? NSLocalizedString(@"DAYS_MANY", nil):
		NSLocalizedString((days == 1) ? @"DAY_ONE" : @"DAYS_ZERO", nil) animated:animated];
	[_hoursDescriptionLabel setText:(hours > 1)? NSLocalizedString(@"HOURS_MANY", nil):
		NSLocalizedString((hours == 1) ? @"HOUR_ONE" : @"HOURS_ZERO", nil) animated:animated];
	[_minutesDescriptionLabel setText:(minutes > 1)? NSLocalizedString(@"MINUTES_MANY", nil):
		NSLocalizedString((minutes == 1) ? @"MINUTE_ONE" : @"MINUTES_ZERO", nil) animated:animated];
	[_secondsDescriptionLabel setText:(seconds > 1)? NSLocalizedString(@"SECONDS_MANY", nil):
		NSLocalizedString((seconds == 1) ? @"SECOND_ONE" : @"SECONDS_ZERO", nil) animated:animated];
	
	_contentView.hidden = NO;
}

#pragma mark - Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<PageView: 0x%p; frame = (%.1f %.1f; %.1f %.1f); alpha = %.1f; layer = <CALayer: %@>>", self, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height, self.alpha, _contentView.layer];
}

@end
