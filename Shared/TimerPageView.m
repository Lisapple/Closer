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

@synthesize timeLabelLanscape = _timeLabelLanscape, descriptionLabelLandscape = _descriptionLabelLandscape;
@synthesize leftButtonLandscape = _leftButtonLandscape;
@synthesize nameLabelLandscape = _nameLabelLandscape;
@synthesize backgroundImageViewLandscape;
@synthesize infoButtonLandscape = _infoButtonLandscape;

static UINib * nib = nil, * landscapeNib = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		nib = [UINib nibWithNibName:@"TimerPageView" bundle:[NSBundle mainBundle]];
	}
}


#pragma mark - Landscape Nib Management

+ (UINib *)landscapeNib
{
	if (!landscapeNib) {
		landscapeNib = [UINib nibWithNibName:@"TimerPageViewLandscape" bundle:[NSBundle mainBundle]];
	}
	
	return landscapeNib;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[nib instantiateWithOwner:self options:nil];
		[self addSubview:_contentView];
		
		/*
		[[TimerPageView landscapeNib] instantiateWithOwner:self options:nil];
		[self addSubview:_contentViewLandscape];
		*/
		
		UIFont * font = [UIFont fontWithName:@"Helvetica-Light" size:10.];
		if (!font) { // If the "Helvetica Light" isn't available (iOS 4.3), set system ("Helvetica") as font
			_timeLabel.font = [UIFont systemFontOfSize:72.];
			_descriptionLabel.font = [UIFont systemFontOfSize:24.];
			_nameLabel.font = [UIFont systemFontOfSize:17.];
		}
		
		[_timerView addTarget:self
					   action:@selector(timerDidSelectAction:)
			 forControlEvents:UIControlEventTouchUpInside];
		
		updateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification
														  object:nil
														   queue:[NSOperationQueue currentQueue]
													  usingBlock:^(NSNotification * notification) {
														  /* If the current timer's endDate change, reset the timer */
														  if (self.countdown.currentDuration.doubleValue != duration && !isPaused) { //if (![self.countdown.endDate isEqualToDate:nextEndDate]) {
															  
															  duration = countdown.currentDuration.doubleValue;
															  remainingSeconds = duration;
															  countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:duration];
															  _timerView.progression = 0.;
															  
															  isPaused = YES;
															  
															  NSDebugLog(@"End date changed for \"%@\"", self.countdown.name);
														  }
														  
														  _nameLabel.text = _nameLabelLandscape.text = self.countdown.name;
													  }];
		
		continueObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"TimerDidContinueNotification"
														  object:nil
														   queue:[NSOperationQueue currentQueue]
													  usingBlock:^(NSNotification * notification) {
														  if (notification.object == self.countdown && isPaused) {
															  [self start];
														  }
													  }];
		// @TODO: Do something with updateObserver and continueObserver
    }
    return self;
}

- (void)setCountdown:(Countdown *)aCountdown
{
	countdown = aCountdown;
	
	_nameLabel.text = _nameLabelLandscape.text = aCountdown.name;
	
	if (countdown.durations.count) {
		duration = [countdown.durations[countdown.durationIndex % countdown.durations.count] doubleValue];
		remainingSeconds = [countdown.endDate timeIntervalSinceNow];
	}
	
	if (remainingSeconds <= 0.) { // If the timer is finished
		isPaused = YES;
		isFinished = YES;
		_timeLabel.text = _timeLabelLanscape.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = YES;
		
		
		UIImage * image = (isPaused)? [UIImage imageNamed:@"restart-button"] : [UIImage imageNamed:@"pause-button"];
		[_leftButton setImage:image forState:UIControlStateNormal];
		[_leftButtonLandscape setImage:image forState:UIControlStateNormal];
	}
	
	[self update];
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
	if (self.countdown.durations.count == 0) {
	
		_timeLabel.text = NSLocalizedString(@"No Durations", nil);
		_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = YES;
		
	} else if (!isPaused) {
		if (countdown.endDate && countdown.durations.count) {
			remainingSeconds = [countdown.endDate timeIntervalSinceNow];
			
			if (remainingSeconds >= 0.) {
				_timerView.progression = (duration - remainingSeconds) / duration;
				_timeLabel.text = _timeLabelLanscape.text = [self formattedDuration];
				_descriptionLabel.text = _descriptionLabelLandscape.text = [self formattedDescription];
				_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = NO;
				
			} else { // Timer done or paused
				if (!isFinished) {
					if (countdown.promptState == PromptStateEveryTimers
						|| (countdown.promptState == PromptStateEnd && countdown.durationIndex == (countdown.durations.count - 1))) { // Pause the timer and wait for the used to tap on "Continue"
						[self pause];
						_timerView.progression = 1.;
						_timeLabel.text = _timeLabelLanscape.text = NSLocalizedString(@"Continue", nil);
						_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = YES;
						isFinished = YES;
						
					} else { // Start the next timer
						countdown.durationIndex++;
						duration = countdown.currentDuration.doubleValue;
						countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:duration];
						isFinished = NO;
						
						_timeLabel.text = _timeLabelLanscape.text = [self formattedDuration];
						_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = NO;
					}
				}
			}
		} else {
			_timeLabel.text = _timeLabelLanscape.text = NSLocalizedString(@"Continue", nil);
		}
	}
}

- (IBAction)pauseButtonAction:(id)sender
{
	if (isPaused) { // If already paused, reset the timer
		remainingSeconds = duration = self.countdown.currentDuration.doubleValue;
		_timerView.progression = 0.;
	}
	
	[self tooglePause];
}

- (void)tooglePause
{
	if (self.countdown.durations.count == 0) { // Don't allow "start" if no durations
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
	
	_timeLabel.text = _timeLabelLanscape.text = NSLocalizedString(@"Resume", nil);
	
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
	UIImage * image = (isPaused)? [UIImage imageNamed:@"restart-button"] : [UIImage imageNamed:@"pause-button"];
	[_leftButton setImage:image forState:UIControlStateNormal];
	[_leftButtonLandscape setImage:image forState:UIControlStateNormal];
	
	_descriptionLabel.hidden = _descriptionLabelLandscape.hidden = isPaused;
	
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

- (void)setOrientation:(UIInterfaceOrientation)newOrientation
{
	orientation = newOrientation;
	
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		
		_contentView.hidden = NO;
		_contentViewLandscape.hidden = YES;
		 
		/*
		[self addSubview:_contentView];
		[_contentViewLandscape removeFromSuperview];
		*/
	} else if (UIInterfaceOrientationIsLandscape(orientation)) {
		
		/* Load Landscape Nib if it's not done yet */
		if (!_contentViewLandscape) {
			[[TimerPageView landscapeNib] instantiateWithOwner:self options:nil];
			NSDebugLog(@"Instantiate landscapeNib.");
			
			UIFont * font = [UIFont fontWithName:@"Helvetica-Light" size:10.];
			if (!font) { // If the "Helvetica Light" isn't available (iOS 4.3), set system ("Helvetica") as font
				_timeLabelLanscape.font = [UIFont systemFontOfSize:72.];
				_descriptionLabelLandscape.font = [UIFont systemFontOfSize:24.];
				_nameLabelLandscape.font = [UIFont systemFontOfSize:17.];
			}
			
			[self addSubview:_contentViewLandscape];
			
			self.countdown = self.countdown;// Force UI reload
		}
		
		/*
		 [self addSubview:_contentViewLandscape];
		[_contentView removeFromSuperview];
		 */
		
		_contentView.hidden = YES;
		_contentViewLandscape.hidden = NO;
	}
	
	[_timerView addTarget:self
				   action:@selector(timerDidSelectAction:)
		 forControlEvents:UIControlEventTouchUpInside];
	
	[self update];
}

#pragma - Page Resources Management

- (void)load
{
	
}

- (void)unload
{
	
}

@end
