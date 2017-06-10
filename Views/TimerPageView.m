//
//  TimerPageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "TimerPageView.h"
#import "UIView+addition.h"
#import "Countdown+addition.h"

NSString * const TimerDidContinueNotification = @"TimerDidContinueNotification";

@interface PageView ()

- (void)handleDoubleTap;

@end

@interface TimerPageView ()
@property (nonatomic, assign) IBOutlet UIView * contentView;
@property (nonatomic, strong) IBOutlet TimerView * timerView;

@property (nonatomic, strong) IBOutlet CCLabel * timeLabel;
@property (nonatomic, strong) IBOutlet UILabel * descriptionLabel;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundImageView;

@property (nonatomic, assign) BOOL dragging, idleTimerDisabled;
@property (nonatomic, assign) CGPoint startLocation, totalOffset;

@property (nonatomic, assign) NSTimeInterval remainingSeconds;
/// Duration of the current timer
@property (nonatomic, assign) NSTimeInterval duration;
/// adjustement offset when modifying current timer progression (by scrolling)
@property (nonatomic, assign) NSTimeInterval offset;

@property (nonatomic, strong) NSDate * nextEndDate;
@property (nonatomic, assign) BOOL isWaiting, loaded;

- (IBAction)pauseButtonAction:(id)sender;

@end

@implementation TimerPageView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		UINib * nib = [UINib nibWithNibName:@"TimerPageView" bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self addSubview:_contentView];
		
		[_timerView addParallaxEffect:(ParallaxAxisVertical | ParallaxAxisHorizontal) offset:15];
		[_timerView addTarget:self action:@selector(timerDidSelectAction:)
			 forControlEvents:UIControlEventTouchUpInside];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:CountdownDidUpdateNotification
														  object:nil queue:nil
													  usingBlock:^(NSNotification * notification) {
														  // If the current timer's endDate change, reset the timer
														  if (self.countdown.currentDuration.doubleValue != _duration && !self.countdown.isPaused) {
															  _duration = self.countdown.currentDuration.doubleValue;
															  _remainingSeconds = _duration;
															  _timerView.progression = 0.;
															  [self.countdown reset];
															  NSDebugLog(@"End date changed for \"%@\"", self.countdown.name);
															  [self reload];
														  }
													  }];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:TimerDidContinueNotification
														  object:nil queue:nil
													  usingBlock:^(NSNotification * notification) {
														  if (notification.object == self.countdown && self.countdown.isPaused) {
															  self.isWaiting = NO;
															  [self start];
														  }
													  }];
		
		UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(timerDidDragged:)];
		pan.maximumNumberOfTouches = 1;
		pan.delegate = self;
		for (UIGestureRecognizer * gesture in self.gestureRecognizers)
			[pan requireGestureRecognizerToFail:gesture];
		for (UIGestureRecognizer * gesture in self.superview.gestureRecognizers)
			[pan requireGestureRecognizerToFail:gesture];
		[self.timerView addGestureRecognizer:pan];
		
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
	
	if (self.countdown.durations.count) {
		_duration = self.countdown.durations[(self.countdown.durationIndex % self.countdown.durations.count)].doubleValue;
		_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
	}
	
	if (self.countdown.endDate && _remainingSeconds <= 0.) { // If the timer is finished
		self.countdown.durationIndex++;
		[self.countdown reset];
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = YES;
		
	} else if (!self.countdown.endDate) {
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
		_descriptionLabel.hidden = YES;
	}
	
	[self setNeedsUpdateStyle];
	[self update];
}

- (void)setTextColor:(UIColor *)textColor
{
	_timerView.tintColor = textColor;
	
	_timeLabel.textColor = textColor;
	_descriptionLabel.textColor = textColor;
}

- (void)styleDidChange:(CountdownStyle)style
{
	_contentView.backgroundColor = [[UIColor backgroundColorForStyle:style] colorWithAlphaComponent:0.7];
	[self setTextColor:[UIColor textColorForStyle:style]];
}

- (void)viewWillShow:(BOOL)animated
{
	[super viewWillShow:animated];
	
	if (_duration < self.minDurationBeforeIdle && !_idleTimerDisabled) {
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
	
	return NSLocalizedString((seconds > 1) ? @"seconds" : ((ceil(seconds) == 1.) ? @"second" : @"SECONDS_ZERO"), nil);
}

- (NSString *)formattedDescription
{
	return [self formattedDescriptionForDuration:self.countdown.endDate.timeIntervalSinceNow];
}

- (void)blinkIfNeeded
{
	if (0. < _remainingSeconds && _remainingSeconds <= 5.) {
		[UIView animateKeyframesWithDuration:1. delay:0.
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
	if (_remainingSeconds < self.minDurationBeforeIdle && !_idleTimerDisabled) {
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
	
	if (self.countdown.isPaused) // Paused
		[_timerView cancelProgressionAnimation];
	else { // Not paused
		if (self.countdown.endDate) { // Playing
			BOOL animated = ([[NSScanner scannerWithString:_timeLabel.text] scanInt:nil]); // Don't animate from text (Resume, Continue, etc.)
			
			_remainingSeconds = self.countdown.endDate.timeIntervalSinceNow;
			BOOL isFinished = (_remainingSeconds < 0);
			if (!isFinished && _duration > 1.) { // Remaining time
				
				[self disableIdleTimerIfNeeded];
				[self blinkIfNeeded];
				
				[_timerView setProgression:MIN((_duration - _remainingSeconds) / (_duration - 1.), 1)
								  animated:YES];
				
				[_timeLabel setText:[self formattedDuration] animated:animated];
				_descriptionLabel.text = [self formattedDescription];
				_descriptionLabel.hidden = NO;
				
			} else if (isFinished) { // Timer finished
				if (self.countdown.promptState == PromptStateEveryTimers ||
					(self.countdown.promptState == PromptStateEnd && self.countdown.durationIndex == (self.countdown.durations.count - 1))) { // Finished and waiting the user to continue
					// Pause the timer and wait for the used to tap on "Continue"
					[self pause];
					[_timerView cancelProgressionAnimation];
					_timerView.progression = 0.;
					_timeLabel.text = NSLocalizedString(@"Continue", nil);
					_descriptionLabel.hidden = YES;
					_isWaiting = YES;
					
				} else { // Start next duration
					self.countdown.durationIndex++;
					_duration = self.countdown.currentDuration.doubleValue;
					self.countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:_duration];
					_isWaiting = NO;
					[_timeLabel setText:[self formattedDuration] animated:animated];
					_descriptionLabel.hidden = NO;
				}
			}
		} else // Waiting for user to continue
			_timeLabel.text = NSLocalizedString(@"Continue", nil);
	}
}

- (IBAction)pauseButtonAction:(id)sender
{
	[self tooglePause];
}

- (void)tooglePause
{
	if (self.countdown.durations.count == 0) // Don't allow to start if no durations
		[self pause];
	else
		(self.countdown.isPaused) ? [self start] : [self pause];
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
	[self.countdown resumeWithOffset:_offset];
	
	if (ABS(self.countdown.endDate.timeIntervalSinceNow) < 1) { // Already finished, start next duration (or from start)
		self.countdown.durationIndex = (self.countdown.durationIndex + 1) % self.countdown.durations.count;
		_duration = self.countdown.currentDuration.doubleValue;
		self.countdown.endDate = [NSDate dateWithTimeIntervalSinceNow:_duration];
		_isWaiting = NO;
		_timeLabel.animatedText = [self formattedDuration];
		_descriptionLabel.hidden = NO;
	}
	
	_offset = 0;
	_duration = self.countdown.currentDuration.doubleValue;
	
	[self reload];
	[self disableIdleTimerIfNeeded];
}

- (void)reload
{
	if (self.countdown.isPaused)
		_timeLabel.text = NSLocalizedString(@"Resume", nil);
	
	_descriptionLabel.hidden = (self.countdown.isPaused);
	
	[self update];
}

- (void)reset
{
	if (self.countdown.isPaused) { // If already paused, reset the timer
		_timerView.progression = 0.;
		_offset = 0;
		[self.countdown reset];
		_remainingSeconds = _duration = self.countdown.currentDuration.doubleValue;
	}
	[self start];
}

- (IBAction)timerDidSelectAction:(id)sender
{
	[self tooglePause];
	
	if (self.countdown.durations.count == 0) {
		NSString * URLString = [NSString stringWithFormat:@"closer://countdown/%@/settings/durations/add", self.countdown.identifier];
		if ([UIApplication instancesRespondToSelector:@selector(openURL:options:completionHandler:)])
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
		else
IGNORE_DEPRECATION_BEGIN
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
IGNORE_DEPRECATION_END
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return !(_dragging);
}

- (void)timerDidDragged:(UIGestureRecognizer *)gesture
{
	if (!self.countdown.isPaused || self.countdown.durations.count == 0)
		return ;
	
	if ([self.superview isKindOfClass:UIScrollView.class]) { // iPhone
		// Don't start the pan gesture (set set the timer progression by dragging up/down) if the user starts scrolling to right/left
		int contentOffsetX = ceil(((UIScrollView *)self.superview).contentOffset.x);
		if ((contentOffsetX % (int)self.frame.size.width) != 0)
			return ;
	}

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
		CGFloat offset = _totalOffset.y / kIndexOffset;
		
		NSUInteger count = self.countdown.durations.count;
		NSInteger dIndex = (_offset / _duration) + offset;
		NSInteger index = self.countdown.durationIndex + dIndex;
		if /**/ (index >= count) { index %= count; }
		else if (index < 0) { index += count; }
		self.countdown.durationIndex = index;
		CGFloat progression = (_offset / _duration) + offset - floor(offset); progression -= floor(progression);
		
		if (dIndex != 0) {
			_duration = self.countdown.currentDuration.doubleValue;
			_offset = -_duration * progression;
			[self.countdown reset];
			[self.countdown pause];
		} else
			_offset -= _duration * progression;
		
		[self start];
	}
#undef kIndexOffset
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	if ([touches.anyObject tapCount] >= 2)
		[self handleDoubleTap];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
