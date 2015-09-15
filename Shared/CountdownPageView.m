//
//  PageViewController.m
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CountdownPageView.h"

#import "UIView+addition.h"

@interface CountdownPageView (PrivatesMethods)

+ (UINib *)landscapeNib;

- (void)setLabelFontDescription:(FontDescription *)fontDescription;
- (void)setDescriptionLabelFontDescription:(FontDescription *)fontDescription;
- (void)setNameFontDescription:(FontDescription *)fontDescription;

@end

@interface CountdownPageView ()
{
	CGPoint _location;
	BOOL idleTimerDisabled;
}
@end

@implementation CountdownPageView

// Private
@synthesize daysLabel, hoursLabel, minutesLabel, secondsLabel;
@synthesize daysDescriptionLabel, hoursDescriptionLabel, minutesDescriptionLabel, secondsDescriptionLabel;
@synthesize nameLabel;

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		UINib * nib = [UINib nibWithNibName:@"CountdownPageView" bundle:[NSBundle mainBundle]];
		[nib instantiateWithOwner:self options:nil];
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.scrollView addSubview:_contentView];
		
		idleTimerDisabled = NO;
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	NSDate * date = countdown.endDate;
	NSTimeInterval timeInterval = date.timeIntervalSinceNow;
	timeInterval = (timeInterval > 0.) ? timeInterval : 0.;// Clip timeInterval to zero
	
	int days = (int)(timeInterval / (24. * 60. * 60.));
	
	daysLabel.hidden = (days == 0);
	daysDescriptionLabel.hidden = (days == 0);
	
	CGFloat totalHeight = hoursLabel.frame.size.height + minutesLabel.frame.size.height
	+ secondsLabel.frame.size.height + nameLabel.frame.size.height;
	if (days)
		totalHeight += daysLabel.frame.size.height;
	
	int numberOfLabels = (days) ? 5 : 4;
	CGFloat margin = ceilf((self.frame.size.height - 20. - totalHeight) / (float)(numberOfLabels + 1));
	
	CGFloat y = margin;
	if (days > 0) {
		[daysLabel setY:y];
		[daysDescriptionLabel setY:(y + 25.)];
		y += margin + daysLabel.frame.size.height;
	}
	
	[hoursLabel setY:y];
	[hoursDescriptionLabel setY:(y + 25.)];
	
	y += margin + hoursLabel.frame.size.height;
	[minutesLabel setY:y];
	[minutesDescriptionLabel setY:(y + 25.)];
	
	y += margin + minutesLabel.frame.size.height;
	[secondsLabel setY:y];
	[secondsDescriptionLabel setY:(y + 25.)];
	
	y += margin + secondsLabel.frame.size.height;
	[nameLabel setY:y];
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
    daysLabel.textColor = hoursLabel.textColor = minutesLabel.textColor = secondsLabel.textColor = textColor;
    daysDescriptionLabel.textColor = hoursDescriptionLabel.textColor = minutesDescriptionLabel.textColor = secondsDescriptionLabel.textColor = textColor;
    
	nameLabel.textColor = textColor;
	
    self.infoButton.tintColor = textColor;
}

- (void)setCountdown:(Countdown *)aCountdown
{
	countdown = aCountdown;
	
	nameLabel.text = countdown.name;
	
	self.style = countdown.style;
}

- (void)viewWillShow:(BOOL)animated
{
	[super viewWillShow:animated];
	
	if (ABS(countdown.endDate.timeIntervalSinceNow) < 3. * 60. && !idleTimerDisabled) {
		[[UIApplication sharedApplication] disableIdleTimer];
		idleTimerDisabled = YES;
	}
}

- (void)viewDidHide:(BOOL)animated
{
	[super viewDidHide:animated];
	
	if (idleTimerDisabled) {
		[[UIApplication sharedApplication] enableIdleTimer];
		idleTimerDisabled = NO;
	}
}

- (void)update
{
	[self setNeedsLayout];
	
	NSDate * date = countdown.endDate;
	NSTimeInterval timeInterval = date.timeIntervalSinceNow;
	timeInterval = (timeInterval > 0.)? timeInterval: 0.;// Clip timeInterval to zero
	
	NSUInteger days = timeInterval / (24. * 60. * 60.);
	timeInterval -= (days * 24 * 60 * 60);
	
	NSUInteger hours = timeInterval / (60. * 60.);
	timeInterval -= (hours * 60 * 60);
	
	NSUInteger minutes = timeInterval / 60.;
	timeInterval -= (minutes * 60);
	
	NSUInteger seconds = timeInterval;
	
	daysLabel.hidden = (days == 0);
	daysDescriptionLabel.hidden = (days == 0);
	
	if (days > 0) {
		daysLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(days, NO)];
		hoursLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(hours, YES)];
	} else {
		hoursLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(hours, YES)];
	}
	
	minutesLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(minutes, YES)];
	secondsLabel.animatedText = [NSString stringWithFormat:@"%@", stringFormat(seconds, YES)];
	
	daysDescriptionLabel.animatedText = (days > 1)? NSLocalizedString(@"DAYS_MANY", nil):
	((days == 1)? NSLocalizedString(@"DAY_ONE", nil): NSLocalizedString(@"DAYS_ZERO", nil));
	hoursDescriptionLabel.animatedText = (hours > 1)? NSLocalizedString(@"HOURS_MANY", nil):
	((hours == 1)? NSLocalizedString(@"HOUR_ONE", nil): NSLocalizedString(@"HOURS_ZERO", nil));
	minutesDescriptionLabel.animatedText = (minutes > 1)? NSLocalizedString(@"MINUTES_MANY", nil):
	((minutes == 1)? NSLocalizedString(@"MINUTE_ONE", nil): NSLocalizedString(@"MINUTES_ZERO", nil));
	secondsDescriptionLabel.animatedText = (seconds > 1)? NSLocalizedString(@"SECONDS_MANY", nil):
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
	position = aPosition;
	
	CGRect rect = _contentView.frame;
	self.frame = CGRectMake(position.x, position.y, rect.size.width, rect.size.height);
	
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
