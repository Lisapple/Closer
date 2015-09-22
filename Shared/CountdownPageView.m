//
//  PageViewController.m
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CountdownPageView.h"

#import "UIView+addition.h"

@interface CountdownPageView ()

@property (nonatomic, assign) IBOutlet UIView * contentView;
@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) BOOL idleTimerDisabled;

@end

@implementation CountdownPageView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		UINib * nib = [UINib nibWithNibName:@"CountdownPageView" bundle:[NSBundle mainBundle]];
		[nib instantiateWithOwner:self options:nil];
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.scrollView addSubview:_contentView];
		
		_idleTimerDisabled = NO;
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	NSDate * date = self.countdown.endDate;
	NSTimeInterval timeInterval = date.timeIntervalSinceNow;
	timeInterval = (timeInterval > 0.) ? timeInterval : 0.;// Clip timeInterval to zero
	
	int days = (int)(timeInterval / (24. * 60. * 60.));
	
	_daysLabel.hidden = (days == 0);
	_daysDescriptionLabel.hidden = (days == 0);
	
	CGFloat totalHeight = _hoursLabel.frame.size.height + _minutesLabel.frame.size.height
	+ _secondsLabel.frame.size.height + _nameLabel.frame.size.height;
	if (days)
		totalHeight += _daysLabel.frame.size.height;
	
	int numberOfLabels = (days) ? 5 : 4;
	CGFloat margin = ceilf((self.frame.size.height - 20. - totalHeight) / (float)(numberOfLabels + 1));
	
	CGFloat y = margin;
	if (days > 0) {
		[_daysLabel setY:y];
		[_daysDescriptionLabel setY:(y + 25.)];
		y += margin + _daysLabel.frame.size.height;
	}
	
	[_hoursLabel setY:y];
	[_hoursDescriptionLabel setY:(y + 25.)];
	
	y += margin + _hoursLabel.frame.size.height;
	[_minutesLabel setY:y];
	[_minutesDescriptionLabel setY:(y + 25.)];
	
	y += margin + _minutesLabel.frame.size.height;
	[_secondsLabel setY:y];
	[_secondsDescriptionLabel setY:(y + 25.)];
	
	y += margin + _secondsLabel.frame.size.height;
	[_nameLabel setY:y];
	[self.infoButton setY:y];
	
	UIView * containerView = _contentView.subviews.lastObject;
	CGRect frame = containerView.frame;
	frame.origin.x = ceilf((self.frame.size.width - containerView.frame.size.width) / 2.);
	frame.origin.y = ceilf((self.frame.size.height - containerView.frame.size.height) / 2.);
	containerView.frame = frame;
}

NSString * stringFormat(NSUInteger value, BOOL addZero)
{
	if (value <= 0)
		return (addZero)? @"00" : @"0";
	
	return [NSString stringWithFormat:((addZero && value < 10) ? @"0%ld" : @"%ld"), (long)value];
}

- (void)setStyle:(PageViewStyle)aStyle
{
	super.style = aStyle;
	
	_contentView.backgroundColor = [[UIColor backgroundColorForPageStyle:aStyle] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForPageStyle:aStyle]];
}

- (void)setTextColor:(UIColor *)textColor
{
    _daysLabel.textColor = _hoursLabel.textColor = _minutesLabel.textColor = _secondsLabel.textColor = textColor;
    _daysDescriptionLabel.textColor = _hoursDescriptionLabel.textColor = _minutesDescriptionLabel.textColor = _secondsDescriptionLabel.textColor = textColor;
    
	_nameLabel.textColor = textColor;
	
    self.infoButton.tintColor = textColor;
}

- (void)setCountdown:(Countdown *)aCountdown
{
	super.countdown = aCountdown;
	
	_nameLabel.text = self.countdown.name;
	
	self.style = self.countdown.style;
}

- (void)viewWillShow:(BOOL)animated
{
	[super viewWillShow:animated];
	
	if (ABS(self.countdown.endDate.timeIntervalSinceNow) < 3. * 60. && !_idleTimerDisabled) {
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
	[self setNeedsLayout];
	
	NSDate * date = self.countdown.endDate;
	NSTimeInterval timeInterval = date.timeIntervalSinceNow;
	timeInterval = (timeInterval > 0.)? timeInterval: 0.;// Clip timeInterval to zero
	
	NSUInteger days = timeInterval / (24. * 60. * 60.);
	timeInterval -= (days * 24 * 60 * 60);
	
	NSUInteger hours = timeInterval / (60. * 60.);
	timeInterval -= (hours * 60 * 60);
	
	NSUInteger minutes = timeInterval / 60.;
	timeInterval -= (minutes * 60);
	
	NSUInteger seconds = timeInterval;
	
	_daysLabel.hidden = (days == 0);
	_daysDescriptionLabel.hidden = (days == 0);
	
	if (days > 0) {
		_daysLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(days, NO)];
		_hoursLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(hours, YES)];
	} else {
		_hoursLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(hours, YES)];
	}
	
	_minutesLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(minutes, YES)];
	_secondsLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(seconds, YES)];
	
	_daysDescriptionLabel.animatedText = (days > 1)? NSLocalizedString(@"DAYS_MANY", nil):
	((days == 1)? NSLocalizedString(@"DAY_ONE", nil): NSLocalizedString(@"DAYS_ZERO", nil));
	_hoursDescriptionLabel.animatedText = (hours > 1)? NSLocalizedString(@"HOURS_MANY", nil):
	((hours == 1)? NSLocalizedString(@"HOUR_ONE", nil): NSLocalizedString(@"HOURS_ZERO", nil));
	_minutesDescriptionLabel.animatedText = (minutes > 1)? NSLocalizedString(@"MINUTES_MANY", nil):
	((minutes == 1)? NSLocalizedString(@"MINUTE_ONE", nil): NSLocalizedString(@"MINUTES_ZERO", nil));
	_secondsDescriptionLabel.animatedText = (seconds > 1)? NSLocalizedString(@"SECONDS_MANY", nil):
	((seconds == 1)? NSLocalizedString(@"SECOND_ONE", nil): NSLocalizedString(@"SECONDS_ZERO", nil));
}

- (IBAction)showSettings:(id)sender
{
	/* Show settings */
	if ([self.delegate respondsToSelector:@selector(pageViewWillShowSettings:)])
		[self.delegate pageViewWillShowSettings:self];
}

- (CGPoint)position
{
	return _contentView.frame.origin;
}

- (void)setPosition:(CGPoint)aPosition
{
	self.position = aPosition;
	
	CGRect rect = _contentView.frame;
	self.frame = CGRectMake(self.position.x, self.position.y, rect.size.width, rect.size.height);
	
	NSDebugLog(@"{%.1f, %.1f} {%.1f, %.1f}",
			   _contentView.frame.origin.x, _contentView.frame.origin.y,
			   _contentView.frame.size.width, _contentView.frame.size.height);
}

#pragma mark -
#pragma Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<PageView: 0x%p; frame = (%.1f %.1f; %.1f %.1f); alpha = %.1f; layer = <CALayer: %@>>", self, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height, self.alpha, _contentView.layer];
}

@end
