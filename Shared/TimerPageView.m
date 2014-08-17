//
//  TimerPageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "TimerPageView.h"

@interface TimerPageView ()
{
	id updateObserver, continueObserver;
}
@end

@implementation TimerPageView

// Public
@synthesize timerView = _timerView;

// Private
@synthesize timeLabel = _timeLabel, descriptionLabel = _descriptionLabel;
@synthesize leftButton = _leftButton;
@synthesize nameLabel = _nameLabel;
@synthesize backgroundImageView;
@synthesize infoButton = _infoButton;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		UINib * nib = [UINib nibWithNibName:@"TimerPageView" bundle:[NSBundle mainBundle]];
		[nib instantiateWithOwner:self options:nil];
		
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.scrollView addSubview:_contentView];
		
		// On iOS 6, create a custom info button (because tint color for info button doesn't work)
		if (!TARGET_IS_IOS7_OR_LATER()) {
			UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
			button.frame = _infoButton.frame;
			button.autoresizingMask = _infoButton.autoresizingMask;
			NSString * actionString = [_infoButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside].lastObject;
			[button addTarget:self
					   action:NSSelectorFromString(actionString)
			 forControlEvents:UIControlEventTouchUpInside];
			_infoButton.hidden = YES;
			_tintedInfoButton = button;
			[_contentView.subviews.lastObject addSubview:_tintedInfoButton];
		}
		
		[_timerView addTarget:self
					   action:@selector(timerDidSelectAction:)
			 forControlEvents:UIControlEventTouchUpInside];
		
		updateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification
																		   object:nil
																			queue:[NSOperationQueue currentQueue]
																	   usingBlock:^(NSNotification * notification)
						  {
							  /* If the current timer's endDate change, reset the timer */
							  if (countdown.currentDuration.doubleValue != duration && !isPaused) {
								  
								  duration = countdown.currentDuration.doubleValue;
								  remainingSeconds = duration;
								  countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:duration];
								  _timerView.progression = 0.;
								  
								  isPaused = YES;
								  
								  NSDebugLog(@"End date changed for \"%@\"", countdown.name);
							  }
							  
							  _nameLabel.text = countdown.name;
						  }];
		
		continueObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"TimerDidContinueNotification"
																			 object:nil
																			  queue:[NSOperationQueue currentQueue]
																		 usingBlock:^(NSNotification * notification)
							{
								if (notification.object == countdown && isPaused)
									[self start];
							}];
		// @TODO: Do something with updateObserver and continueObserver
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	_tintedInfoButton.frame = _infoButton.frame;
	
	UIView * containerView = _contentView.subviews.lastObject;
	CGRect frame = containerView.frame;
	frame.origin.x = ceilf((self.frame.size.width - containerView.frame.size.width) / 2.);
	frame.origin.y = ceilf((self.frame.size.height - containerView.frame.size.height) / 2.);
	containerView.frame = frame;
}

- (void)setCountdown:(Countdown *)aCountdown
{
	countdown = aCountdown;
	
	self.style = aCountdown.style;
	_nameLabel.text = aCountdown.name;
	
	if (countdown.durations.count) {
		duration = [countdown.durations[countdown.durationIndex % countdown.durations.count] doubleValue];
		remainingSeconds = [countdown.endDate timeIntervalSinceNow];
	}
	
	if (remainingSeconds <= 0.) { // If the timer is finished
		isPaused = YES;
		isFinished = YES;
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = YES;
		
		[self updateLeftButton];
	}
	
	[self update];
}

- (void)setTextColor:(UIColor *)textColor
{
	_timerView.tintColor = textColor;
	
	_timeLabel.textColor = textColor;
	_descriptionLabel.textColor = textColor;
	_nameLabel.textColor = textColor;
}

- (void)setStyle:(PageViewStyle)aStyle
{
	super.style = aStyle;
	
	_contentView.backgroundColor = [[UIColor backgroundColorForPageStyle:aStyle] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForPageStyle:aStyle]];
	
	NSString * name = nil;
	switch (aStyle) {
		case PageViewStyleDay:
			name = @"button-day"; break;
		case PageViewStyleDawn:
			name = @"button-dawn"; break;
		case PageViewStyleOasis:
			name = @"button-oasis"; break;
		case PageViewStyleSpring:
			name = @"button-spring"; break;
		case PageViewStyleNight:
		default:
			name = @"button-night"; break;
	}
	if (!TARGET_IS_IOS7_OR_LATER()) {
		NSString * filename = [NSString stringWithFormat:@"info-%@-iOS6", name];
		[_tintedInfoButton setBackgroundImage:[UIImage imageNamed:filename]
							   forState:UIControlStateNormal];
	} else {
		_infoButton.tintColor = [UIColor textColorForPageStyle:aStyle];
	}
	[self updateLeftButton];
}

- (void)updateLeftButton
{
	NSString * name = nil;
	switch (self.style) {
		case PageViewStyleDay:
			name = @"button-day"; break;
		case PageViewStyleDawn:
			name = @"button-dawn"; break;
		case PageViewStyleOasis:
			name = @"button-oasis"; break;
		case PageViewStyleSpring:
			name = @"button-spring"; break;
		case PageViewStyleNight:
		default:
			name = @"button-night"; break;
	}
	
	NSString * filename = [NSString stringWithFormat:@"%@-%@-iOS%d",
						   ((isPaused) ? @"reset" : @"pause"),
						   name,
						   (TARGET_IS_IOS7_OR_LATER()) ? 7 : 6];
	[_leftButton setImage:[UIImage imageNamed:filename]
				 forState:UIControlStateNormal];
}

- (NSString *)formattedDuration
{
	double seconds = [countdown.endDate timeIntervalSinceNow];
	double days = seconds / (24. * 60. * 60.);
	if (floor(days) >= 2.)
		return [NSString stringWithFormat:@"%d", (int)ceil(days)];
	
	double hours = seconds / (60. * 60.);
	if (floor(hours) >= 2.)
		return [NSString stringWithFormat:@"%d", (int)ceil(hours)];
	
	double minutes = seconds / 60.;
	if (floor(minutes) >= 2.)
		return [NSString stringWithFormat:@"%d", (int)ceil(minutes)];
	
	return [NSString stringWithFormat:@"%d", (int)ceil(seconds)];
}

- (NSString *)formattedDescription
{
	double seconds = [countdown.endDate timeIntervalSinceNow];
	double days = seconds / (24. * 60. * 60.);
	if (floor(days) >= 2.)
		return NSLocalizedString(@"days", nil);
	
	double hours = seconds / (60. * 60.);
	if (floor(hours) >= 2.)
		return NSLocalizedString(@"hours", nil);
	
	double minutes = seconds / 60.;
	if (floor(minutes) >= 2.)
		return NSLocalizedString(@"minutes", nil);
	
	return (seconds > 1) ? NSLocalizedString(@"seconds", nil) : ((ceil(seconds) == 1.) ? NSLocalizedString(@"second", nil) : NSLocalizedString(@"seconds_0", nil));
}

- (void)update
{
	if (countdown.durations.count == 0) {
		
		_timeLabel.text = NSLocalizedString(@"No Durations", nil);
		_descriptionLabel.hidden = YES;
		
	} else if (!isPaused) {
		if (countdown.endDate && countdown.durations.count) {
			remainingSeconds = countdown.endDate.timeIntervalSinceNow;
			
			if (remainingSeconds >= 0.) {
				[_timerView setProgression:(duration - remainingSeconds) / duration
								  animated:YES];
				_timeLabel.text = [self formattedDuration];
				_descriptionLabel.text = [self formattedDescription];
				_descriptionLabel.hidden = NO;
				
			} else { // Timer done or paused
				if (!isFinished) {
					if (countdown.promptState == PromptStateEveryTimers
						|| (countdown.promptState == PromptStateEnd && countdown.durationIndex == (countdown.durations.count - 1))) { // Pause the timer and wait for the used to tap on "Continue"
						[self pause];
						[_timerView setProgression:1. animated:YES];
						_timeLabel.text = NSLocalizedString(@"Continue", nil);
						_descriptionLabel.hidden = YES;
						isFinished = YES;
						
					} else { // Start the next timer
						countdown.durationIndex++;
						duration = countdown.currentDuration.doubleValue;
						countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:duration];
						isFinished = NO;
						
						_timeLabel.text = [self formattedDuration];
						_descriptionLabel.hidden = NO;
					}
				}
			}
		} else {
			_timeLabel.text = NSLocalizedString(@"Continue", nil);
		}
	}
}

- (IBAction)pauseButtonAction:(id)sender
{
	if (isPaused) { // If already paused, reset the timer
		remainingSeconds = duration = countdown.currentDuration.doubleValue;
		_timerView.progression = 0.;
	}
	
	[self tooglePause];
}

- (void)tooglePause
{
	if (countdown.durations.count == 0) { // Don't allow "start" if no durations
		[self pause];
		return ;
	}
	
	if (isPaused) {
		[self start];
	} else {
		[self pause];
	}
}

- (void)pause
{
	isPaused = YES;
	
	_timeLabel.text = NSLocalizedString(@"Resume", nil);
	
	remainingSeconds = [countdown.endDate timeIntervalSinceNow];
	countdown.endDate = nil;
	
	[self reload];
}

- (void)start
{
	isPaused = NO;
	
	/* If the timer is finished, start the next */
	if (isFinished) {
		countdown.durationIndex++;
		remainingSeconds = duration = countdown.currentDuration.doubleValue;
		countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:duration];
		_timerView.progression = 0.;
		isFinished = NO;
	} else {
		countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:(0. < remainingSeconds && remainingSeconds < duration) ? remainingSeconds : duration];
	}
	
	[self reload];
}

- (void)reload
{
	[self updateLeftButton];
	
	_descriptionLabel.hidden = isPaused;
	
	[self update];
}

- (IBAction)timerDidSelectAction:(id)sender
{
	[self tooglePause];
}

- (IBAction)showSettings:(id)sender
{
	/* Show settings */
	if ([self.delegate respondsToSelector:@selector(pageViewWillShowSettings:)])
		[self.delegate pageViewWillShowSettings:self];
}

@end
