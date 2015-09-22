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
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) NSTimeInterval originalDuration, delta;

@property (nonatomic, assign) IBOutlet UIView * contentView;

@property (nonatomic, assign) NSTimeInterval remainingSeconds, duration; // Duration of the current timer
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
							  }
							  _nameLabel.text = self.countdown.name;
							  [self reload];
						  }];
		
		_continueObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"TimerDidContinueNotification"
																			 object:nil
																			  queue:[NSOperationQueue currentQueue]
																		 usingBlock:^(NSNotification * notification)
							{
								if (notification.object == self.countdown && self.countdown.isPaused)
									[self start];
							}];
		
		UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
																			   action:@selector(timerDidDragged:)];
		pan.delegate = self;
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

- (void)setStyle:(PageViewStyle)aStyle
{
	super.style = aStyle;
	
	_contentView.backgroundColor = [[UIColor backgroundColorForPageStyle:aStyle] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForPageStyle:aStyle]];
	
	self.infoButton.tintColor = [UIColor textColorForPageStyle:aStyle];
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
	NSString * name = [NSString stringWithFormat:@"button-night-%@", (self.countdown.isPaused) ? @"reset" : @"pause"];
	_leftButton.tintColor = [UIColor textColorForPageStyle:self.countdown.style];
	[_leftButton setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
}

- (NSString *)formattedDurationForDuration:(NSTimeInterval)d
{
	double seconds = d;
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

- (NSString *)formattedDescriptionForDuration:(NSTimeInterval)d
{
	double seconds = d;
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

- (void)update
{
	if (self.countdown.durations.count == 0) {
		
		_timeLabel.text = NSLocalizedString(@"No Durations", nil);
		_descriptionLabel.hidden = YES;
		
	} else if (!self.countdown.isPaused) {
		if (self.countdown.endDate && self.countdown.durations.count) {
			_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
			
			if (_remainingSeconds < 3. * 60. && !_idleTimerDisabled) {
				[[UIApplication sharedApplication] disableIdleTimer];
				_idleTimerDisabled = YES;
			}
			
			if (_remainingSeconds >= 0. && _duration > 1) {
				[_timerView cancelProgressionAnimation];
				[_timerView setProgression:(_duration - _remainingSeconds) / (_duration - 1)
								  animated:YES];
				_timeLabel.text = [self formattedDuration];
				_descriptionLabel.text = [self formattedDescription];
				_descriptionLabel.hidden = NO;
				
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
			} else { // Timer done or paused
				if (!_isFinished) {
					if (self.countdown.promptState == PromptStateEveryTimers ||
						(self.countdown.promptState == PromptStateEnd && self.countdown.durationIndex == (self.countdown.durations.count - 1))) { // Pause the timer and wait for the used to tap on "Continue"
						[self pause];
						[_timerView cancelProgressionAnimation];
						_timerView.progression = 0.;
						_timeLabel.text = NSLocalizedString(@"Continue", nil);
						_descriptionLabel.hidden = YES;
						_isFinished = YES;
						
					} else { // Start the next timer
						self.countdown.durationIndex++;
						_duration = self.countdown.currentDuration.doubleValue;
						self.countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:_duration];
						_isFinished = NO;
						
						_timeLabel.text = [self formattedDuration];
						_descriptionLabel.hidden = NO;
					}
				}
			}
		} else {
			_timeLabel.text = NSLocalizedString(@"Continue", nil);
		}
	} else { // Paused
		[_timerView cancelProgressionAnimation];
	}
}

- (IBAction)pauseButtonAction:(id)sender
{
	if (self.countdown.isPaused) { // If already paused, reset the timer
		_remainingSeconds = _duration = self.countdown.currentDuration.doubleValue;
		_timerView.progression = 0.;
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
		[self.countdown resume];
	}
	
	[self reload];
}

- (void)reload
{
	[self updateLeftButton];
	
	if (self.countdown.isPaused) {
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
	}
	_descriptionLabel.hidden = self.countdown.isPaused;
	
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

- (IBAction)confirmationChangeAction:(id)sender
{
	[self.countdown setDuration:@(_originalDuration)
						atIndex:self.countdown.durationIndex];
	
	_timeLabel.text = NSLocalizedString(@"Resume", nil);
	_remainingSeconds = _duration = self.countdown.currentDuration.doubleValue;
	_isFinished = NO;
	[self reload];
	[self showConfirmationToolbar:NO];
}

- (IBAction)resetChangeAction:(id)sender
{
	_timeLabel.text = NSLocalizedString(@"Resume", nil);
	_remainingSeconds = _duration = self.countdown.currentDuration.doubleValue;
	_isFinished = NO;
	[self.countdown reset];
	[self reload];
	[self showConfirmationToolbar:NO];
}

- (IBAction)showConfirmationToolbar:(BOOL)show
{
	_showingChangeConfirmation = show;
	
	static const NSInteger tag = 1234;
	if (show) {
		CGRect frame = CGRectMake(0., self.frame.size.height,
								  self.frame.size.width, 44.);
		UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:frame];
		toolbar.tag = tag;
        toolbar.tintColor = [UIColor blackColor];
		
		NSString * resetTitle = [NSString stringWithFormat:NSLocalizedString(@"Reset to %@", nil),
								 [self.countdown shortDescriptionOfDurationAtIndex:self.countdown.durationIndex]];
		toolbar.items = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																		 target:self action:@selector(confirmationChangeAction:)],
						   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																		 target:nil action:NULL],
						   [[UIBarButtonItem alloc] initWithTitle:resetTitle
															style:UIBarButtonItemStyleDone
														   target:self action:@selector(resetChangeAction:)] ];
		[self addSubview:toolbar];
		[UIView animateWithDuration:0.15
						 animations:^{
							 toolbar.frame = CGRectMake(0., self.frame.size.height - 44.,
														self.frame.size.width, 44.);
						 }];
		
		if ([self.delegate respondsToSelector:@selector(pageViewWillShowDeleteConfirmation:)]) {
			[self.delegate pageViewWillShowDeleteConfirmation:self]; // @TODO: Use a type for confirmation (xxxDelete and xxxTimer)
		}
		
	} else { // Hide
		[UIView animateWithDuration:0.15
						 animations:^{
							 [self viewWithTag:tag].frame = CGRectMake(0., self.frame.size.height,
																	   self.frame.size.width, 44.);
						 }
						 completion:^(BOOL finished) { [[self viewWithTag:tag] removeFromSuperview]; }];
		
		if ([self.delegate respondsToSelector:@selector(pageViewWillShowDeleteConfirmation:)]) {
			[self.delegate pageViewDidHideDeleteConfirmation:self]; // @TODO: Use a type for confirmation (xxxDelete and xxxTimer)
		}
	}
	
	((UIScrollView *)self.superview).scrollEnabled = !(show);
	self.scrollView.scrollEnabled =  !(show);
	self.infoButton.hidden = (show);
	_leftButton.hidden = (show);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return !(_dragging);
}

- (void)timerDidDragged:(UIGestureRecognizer *)gesture
{
	if (!self.countdown.isPaused)
		return ;
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		_dragging = YES;
		_startLocation = [gesture locationInView:self];
	}
	else if (gesture.state == UIGestureRecognizerStateEnded) {
		_dragging = NO;
		_originalDuration = MIN(MAX(0., _originalDuration + _delta), 7 * 24 * 3600);
		_delta = 0.;
	}
	else {
		if ((int)((UIScrollView *)self.superview).contentOffset.x % (int)self.frame.size.width > 0) // If the user scolls to left or right, stop "dragging to set"
			_dragging = NO;
		else if (_dragging) {
			if (!_showingChangeConfirmation) {
				[self showConfirmationToolbar:YES];
				_originalDuration = ((NSNumber *)self.countdown.currentDuration).doubleValue;
				
				_timerView.progression = 0.;
				_descriptionLabel.hidden = NO;
			}
			
			CGPoint location = [gesture locationInView:self];
			CGFloat offset = location.y - _startLocation.y;
			
			NSInteger d = (int)(-offset / 10.);
			NSInteger step;
			if /**/ (_originalDuration <= 60.)
				step = 1;
			else if (_originalDuration <= 3600)
				step = 60;
			else
				step = 3600;
			
			if (ABS(d) <= 5)
				d *= step;
			else
				d = (ABS(d) - 4) * step * 5 * ((d < 0) ? -1 : 1);
			
			_delta = d;
			NSTimeInterval newDuration = MIN(MAX(0., _originalDuration + d), 7 * 24 * 3600);
			_timeLabel.text = [self formattedDurationForDuration:newDuration];
			_descriptionLabel.text = [self formattedDescriptionForDuration:newDuration];
		}
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:_updateObserver];
	[[NSNotificationCenter defaultCenter] removeObserver:_continueObserver];
}

@end
