//
//  TimerPageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "TimerPageView.h"

@interface TimerPageView ()
@property (nonatomic, strong) id updateObserver, continueObserver;

@property (nonatomic, assign) BOOL dragging, showingChangeConfirmation, idleTimerDisabled;
@property (nonatomic, assign) CGPoint startLocation, totalOffset;
//@property (nonatomic, assign) NSTimeInterval originalDuration, delta;

@property (nonatomic, assign) IBOutlet UIView * contentView;

@property (nonatomic, assign) NSTimeInterval remainingSeconds, duration /* Duration of the current timer */, offset /* adjustement offset when modifying current timer progression (by scrolling) */;
@property (nonatomic, strong) NSDate * nextEndDate;
@property (nonatomic, assign) BOOL isFinished, loaded;

@end

@implementation TimerPageView

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		UINib * nib = [UINib nibWithNibName:@"TimerPageView" bundle:[NSBundle mainBundle]];
		[nib instantiateWithOwner:self options:nil];
		
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.scrollView addSubview:_contentView];
		self.scrollView.delaysContentTouches = NO;
		
		[_timerView addTarget:self
					   action:@selector(timerDidSelectAction:)
			 forControlEvents:UIControlEventTouchUpInside];
		
		_updateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification
																		   object:nil
																			queue:[NSOperationQueue currentQueue]
																	   usingBlock:^(NSNotification * notification)
						  {
							  /* If the current timer's endDate change, reset the timer */
							  if (self.countdown.currentDuration.doubleValue != _duration && !self.countdown.isPaused) {
								  _duration = self.countdown.currentDuration.doubleValue;
								  _remainingSeconds = _duration;
								  _timerView.progression = 0.;
								  [self.countdown reset];
								  NSDebugLog(@"End date changed for \"%@\"", self.countdown.name);
								  [self reload];
							  }
							  if (self.countdown.currentName.length > 0) {
								  // [name]\n[current duration name]
								  NSMutableDictionary * attributes = @{ NSForegroundColorAttributeName : _nameLabel.textColor,
																		NSFontAttributeName : _nameLabel.font }.mutableCopy;
								  NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:self.countdown.name
																											  attributes:attributes];
								  [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
								  attributes[NSForegroundColorAttributeName] = [_nameLabel.textColor colorWithAlphaComponent:0.5];
								  [string appendAttributedString:[[NSAttributedString alloc] initWithString:self.countdown.currentName
																								 attributes:attributes]];
								  _nameLabel.attributedText = string;
							  } else {
								  _nameLabel.text = self.countdown.name;
							  }
						  }];
		
		_continueObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"TimerDidContinueNotification"
																			 object:nil
																			  queue:[NSOperationQueue currentQueue]
																		 usingBlock:^(NSNotification * notification)
							{ if (notification.object == self.countdown && self.countdown.isPaused) { [self start]; } }];
		
		UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(timerDidDragged:)];
		pan.maximumNumberOfTouches = 1;
		pan.delegate = self;
		for (UIGestureRecognizer * gesture in self.gestureRecognizers)
			[pan requireGestureRecognizerToFail:gesture];
		for (UIGestureRecognizer * gesture in self.scrollView.gestureRecognizers)
			[pan requireGestureRecognizerToFail:gesture];
		for (UIGestureRecognizer * gesture in self.superview.gestureRecognizers)
			[pan requireGestureRecognizerToFail:gesture];
		[self addGestureRecognizer:pan];
		
		_idleTimerDisabled = NO;
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	UIView * containerView = _contentView.subviews.lastObject;
	CGRect frame = containerView.frame;
	frame.origin.x = ceilf((self.frame.size.width - containerView.frame.size.width) / 2.);
	frame.origin.y = ceilf((self.frame.size.height - containerView.frame.size.height) / 2.);
	containerView.frame = frame;
	[_timerView setNeedsDisplay];
}

- (void)setCountdown:(Countdown *)aCountdown
{
	super.countdown = aCountdown;
	
	self.style = aCountdown.style;
	_nameLabel.text = aCountdown.name;
	
	if (self.countdown.durations.count) {
		_duration = self.countdown.durations[(self.countdown.durationIndex % self.countdown.durations.count)].doubleValue;
		_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
	}
	
	if (self.countdown.endDate && _remainingSeconds <= 0.) { // If the timer is finished
		_isFinished = YES;
		self.countdown.durationIndex++;
		[self.countdown reset];
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = YES;
		
		[self updateLeftButton];
	} else if (!self.countdown.endDate) {
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = YES;
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

- (void)setStyle:(CountdownStyle)aStyle
{
	super.style = aStyle;
	
	_contentView.backgroundColor = [[UIColor backgroundColorForStyle:aStyle] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForStyle:aStyle]];
	
	self.infoButton.tintColor = [UIColor textColorForStyle:aStyle];
	[self updateLeftButton];
}

- (void)viewWillShow:(BOOL)animated
{
	[super viewWillShow:animated];
	
	if (_duration < 3. * 60. && !_idleTimerDisabled) {
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

- (void)updateLeftButton
{
	_leftButton.imageView.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
	NSString * name = (self.countdown.isPaused) ? @"reset-button" : @"pause-button";
	_leftButton.tintColor = [UIColor textColorForStyle:self.countdown.style];
	[_leftButton setImage:[[UIImage imageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
				 forState:UIControlStateNormal];
}

- (NSString *)formattedDurationForDuration:(NSTimeInterval)seconds
{
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

- (NSString *)formattedDuration
{
	return [self formattedDurationForDuration:self.countdown.endDate.timeIntervalSinceNow];
}

- (NSString *)formattedDescriptionForDuration:(NSTimeInterval)seconds
{
	double days = seconds / (24. * 60. * 60.);
	if (floor(days) >= 2.)
		return NSLocalizedString(@"days", nil);
	
	double hours = seconds / (60. * 60.);
	if (floor(hours) >= 2.)
		return NSLocalizedString(@"hours", nil);
	
	double minutes = seconds / 60.;
	if (floor(minutes) >= 2.)
		return NSLocalizedString(@"minutes", nil);
	
	return (seconds > 1) ? NSLocalizedString(@"seconds", nil) : ((ceil(seconds) == 1.) ? NSLocalizedString(@"second", nil) : NSLocalizedString(@"SECONDS_ZERO", nil));
}

- (NSString *)formattedDescription
{
	return [self formattedDescriptionForDuration:self.countdown.endDate.timeIntervalSinceNow];
}

- (void)blinkIfNeeded
{
	if (0. < _remainingSeconds && _remainingSeconds <= 5.) {
		[UIView animateKeyframesWithDuration:1.
									   delay:0.
									 options:(UIViewKeyframeAnimationOptionAllowUserInteraction)
								  animations:^{
									  UIColor * backgroundColor = _contentView.backgroundColor;
									  [UIView addKeyframeWithRelativeStartTime:0. relativeDuration:0.5 animations:^{
										  _contentView.backgroundColor = [UIColor colorWithRed:1. green:0. blue:0. alpha:0.85]; }];
									  [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
										  _contentView.backgroundColor = backgroundColor; }];
								  }
								  completion:NULL];
	}
}

- (void)disableIdleTimerIfNeeded
{
	if (_remainingSeconds < 3. * 60. && !_idleTimerDisabled) {
		[[UIApplication sharedApplication] disableIdleTimer];
		_idleTimerDisabled = YES;
	}
}

- (void)update
{
	if (self.countdown.durations.count == 0) { // No durations
		_timeLabel.text = NSLocalizedString(@"No Durations", nil);
		_descriptionLabel.hidden = YES;
		return ;
	}
	
	if (self.countdown.isPaused) { // Paused
		[_timerView cancelProgressionAnimation];
	} else { // Not paused
		
		if (self.countdown.endDate) { // Playing
			_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
			if (_remainingSeconds >= 0. && _duration > 1) { // Remaining time
				
				[self disableIdleTimerIfNeeded];
				[self blinkIfNeeded];
				
				[_timerView cancelProgressionAnimation];
				[_timerView setProgression:(_duration - _remainingSeconds) / (_duration - 1.)
								  animated:YES];
				_timeLabel.text = [self formattedDuration];
				_descriptionLabel.text = [self formattedDescription];
				_descriptionLabel.hidden = NO;
				
			} else if (_isFinished || _remainingSeconds <= 0) { // Timer finished // @FIXME: |_remainingSeconds| shoud not be < 0
				
				// Start next duration
				self.countdown.durationIndex++;
				_duration = self.countdown.currentDuration.doubleValue;
				self.countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:_duration];
				_isFinished = NO;
				_timeLabel.text = [self formattedDuration];
				_descriptionLabel.hidden = NO;
				
			} else if (self.countdown.promptState == PromptStateEveryTimers ||
					   (self.countdown.promptState == PromptStateEnd && self.countdown.durationIndex == (self.countdown.durations.count - 1))) { // Finished and waiting the user to continue
				// Pause the timer and wait for the used to tap on "Continue"
				[self pause];
				[_timerView cancelProgressionAnimation];
				_timerView.progression = 0.;
				_timeLabel.text = NSLocalizedString(@"Continue", nil);
				_descriptionLabel.hidden = YES;
				_isFinished = YES;
			}
			
		} else { // Waiting for user to continue
			_timeLabel.text = NSLocalizedString(@"Continue", nil);
		}
	}
}

- (IBAction)pauseButtonAction:(id)sender
{
	if (self.countdown.isPaused) { // If already paused, reset the timer
		_remainingSeconds = _duration = self.countdown.currentDuration.doubleValue;
		_timerView.progression = 0.;
		_offset = -_remainingSeconds;
	}
	
	[self tooglePause];
}

- (void)tooglePause
{
	if (self.countdown.durations.count == 0) { // Don't allow "start" if no durations
		[self pause];
	} else {
		if (self.countdown.isPaused) [self start];
		else [self pause];
	}
}

- (void)pause
{
	_timeLabel.text = NSLocalizedString(@"Resume", nil);
	
	_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
	[self.countdown pause];
	
	[self reload];
}

- (void)start
{
	/* If the timer is finished, start the next */
	if (_isFinished) {
		self.countdown.durationIndex++;
		[self.countdown reset];
		_timerView.progression = 0.;
		_isFinished = NO;
	} else {
		[self.countdown resumeWithOffset:_offset];
		_offset = 0;
		_duration = self.countdown.currentDuration.doubleValue;
	}
	
	[self reload];
}

- (void)reload
{
	[self updateLeftButton];
	
	if (self.countdown.isPaused) {
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
	}
	_descriptionLabel.hidden = (self.countdown.isPaused);
	
	[self update];
}

- (IBAction)timerDidSelectAction:(id)sender
{
	if (!_showingChangeConfirmation)
		[self tooglePause];
}

- (IBAction)showSettings:(id)sender
{
	/* Show settings */
	if ([self.delegate respondsToSelector:@selector(pageViewWillShowSettings:)])
		[self.delegate pageViewWillShowSettings:self];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return !(_dragging);
}

- (void)timerDidDragged:(UIGestureRecognizer *)gesture
{
	if (!self.countdown.isPaused || self.countdown.durations.count == 0)
		return ;
	
	// Don't start the pan gesture (set set the timer progression by dragging up/down) if the user starts scrolling to right/left
	int contentOffsetX = ((UIScrollView *)self.superview).contentOffset.x;
	if (((int)contentOffsetX % (int)self.frame.size.width) > 0)
		return ;

#define kIndexOffset 100.
	
	if (gesture.state == UIGestureRecognizerStateBegan) { // Began
		_dragging = YES;
		_startLocation = [gesture locationInView:self];
		_totalOffset = CGPointZero;
		_offset = _duration - _remainingSeconds;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) { // Changed
		CGFloat offsetY = _totalOffset.y + (_startLocation.y - [gesture locationInView:self].y);
		CGFloat progression = (_offset / _duration) + (offsetY / kIndexOffset) - floor(offsetY / kIndexOffset); progression -= floor(progression);
		
		NSUInteger count = self.countdown.durations.count;
		NSInteger index = self.countdown.durationIndex + (_offset / _duration) + (offsetY / kIndexOffset);
		if /**/ (index >= count) { index %= count; }
		else if (index < 0) { index += count; }
		NSTimeInterval duration = self.countdown.durations[index].doubleValue;
		
		_timerView.progression = progression;
		NSTimeInterval remainingDuration = duration * (1. - progression);
		_timeLabel.text = [self formattedDurationForDuration:remainingDuration];
		_descriptionLabel.text = [self formattedDescriptionForDuration:remainingDuration];
		_descriptionLabel.hidden = NO;
	}
	else if (gesture.state == UIGestureRecognizerStateEnded) { // Ended
		_dragging = NO;
		_totalOffset.y += (_startLocation.y - [gesture locationInView:self].y);
		
		NSUInteger count = self.countdown.durations.count;
		NSInteger dIndex = (_offset / _duration) + (_totalOffset.y / kIndexOffset);
		NSInteger index = self.countdown.durationIndex + dIndex;
		if /**/ (index >= count) { index %= count; }
		else if (index < 0) { index += count; }
		self.countdown.durationIndex = index;
		CGFloat progression = (_offset / _duration) + (_totalOffset.y / kIndexOffset) - floor(_totalOffset.y / kIndexOffset); progression -= floor(progression);
		
		if (dIndex != 0) {
			_duration = self.countdown.currentDuration.doubleValue;
			_offset = -_duration * progression;
			[self.countdown reset];
			[self.countdown pause];
		} else {
			_offset -= _duration * progression;
		}
		
		[self start];
	}
#undef kIndexOffset
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:_updateObserver];
	[[NSNotificationCenter defaultCenter] removeObserver:_continueObserver];
}

@end
