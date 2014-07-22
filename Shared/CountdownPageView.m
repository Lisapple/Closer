//
//  PageViewController.m
//  Closer
//
//  Created by Max on 2/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CountdownPageView.h"

#import "UIView+addition.h"
#import "UILabel+addition.h"

@interface CountdownPageView (PrivatesMethods)

+ (UINib *)landscapeNib;

- (void)setLabelFontDescription:(FontDescription *)fontDescription;
- (void)setDescriptionLabelFontDescription:(FontDescription *)fontDescription;
- (void)setNameFontDescription:(FontDescription *)fontDescription;

@end


@implementation CountdownPageView

// Private
@synthesize daysLabel, hoursLabel, minutesLabel, secondsLabel;
@synthesize daysDescriptionLabel, hoursDescriptionLabel, minutesDescriptionLabel, secondsDescriptionLabel;
@synthesize infoButton;
@synthesize nameLabel;
@synthesize backgroundImageView;
@synthesize backgroundImageName = _backgroundImageName, landscapeBackgroundImageName = _landscapeBackgroundImageName;

@synthesize timeLabelLanscape;
@synthesize infoButtonLandscape;
@synthesize nameLabelLandscape;
@synthesize backgroundImageViewLandscape;

// Public
@synthesize style;

const NSTimeInterval kDoubleTapDelay = 0.35;
const NSTimeInterval kHideDescriptionDelay = 5.;

static CGFloat hoursLabelY, minutesLabelY, secondsLabelY, hoursDescriptionLabelY, minutesDescriptionLabelY, secondsDescriptionLabelY;

static UINib * nib = nil, * landscapeNib = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		nib = [UINib nibWithNibName:@"CountdownPageView" bundle:[NSBundle mainBundle]];
	}
}


#pragma mark - Landscape Nib Management

+ (UINib *)landscapeNib
{
	if (!landscapeNib) {
		landscapeNib = [UINib nibWithNibName:@"CountdownPageViewLandscape" bundle:[NSBundle mainBundle]];
	}
	
	return landscapeNib;
}


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		[nib instantiateWithOwner:self options:nil];
		
		[self addSubview:_contentView];
		
		//_contentViewLandscape.hidden = YES;
		//[self addSubview:_contentViewLandscape]; // @TODO: remove this if unused
		
		hoursLabelY = hoursLabel.frame.origin.y;
		minutesLabelY = minutesLabel.frame.origin.y;
		secondsLabelY = secondsLabel.frame.origin.y;
		hoursDescriptionLabelY = hoursDescriptionLabel.frame.origin.y;
		minutesDescriptionLabelY = minutesDescriptionLabel.frame.origin.y;
		secondsDescriptionLabelY = secondsDescriptionLabel.frame.origin.y;
		
		infoButtonType = -1;
	}
	
	return self;
}

#pragma mark - Accessibility

- (NSString *)accessibleCurrentDate
{
	NSDate * date = countdown.endDate;
	NSTimeInterval timeInterval = [date timeIntervalSinceNow];
	timeInterval = (timeInterval > 0.)? timeInterval: 0.;// Clip timeInterval to zero
	
	unsigned int days = (unsigned int)(timeInterval / (24. * 60. * 60.));
	timeInterval -= (days * 24 * 60 * 60);
	
	unsigned int hours = (unsigned int)(timeInterval / (60. * 60.));
	timeInterval -= (hours * 60 * 60);
	
	unsigned int minutes = (unsigned int)(timeInterval / 60.);
	timeInterval -= (minutes * 60);
	
	unsigned int seconds = timeInterval;
	
	NSString * daysString = (days > 1)? NSLocalizedString(@"DAYS_MANY", nil):
	((days == 1)? NSLocalizedString(@"DAY_ONE", nil): NSLocalizedString(@"DAYS_ZERO", nil));
	NSString * hoursString = (hours > 1)? NSLocalizedString(@"HOURS_MANY", nil):
	((hours == 1)? NSLocalizedString(@"HOUR_ONE", nil): NSLocalizedString(@"HOURS_ZERO", nil));
	NSString * minutesString = (minutes > 1)? NSLocalizedString(@"MINUTES_MANY", nil):
	((minutes == 1)? NSLocalizedString(@"MINUTE_ONE", nil): NSLocalizedString(@"MINUTES_ZERO", nil));
	NSString * secondsString = (seconds > 1)? NSLocalizedString(@"SECONDS_MANY", nil):
	((seconds == 1)? NSLocalizedString(@"SECOND_ONE", nil): NSLocalizedString(@"SECONDS_ZERO", nil));
	
	if (days == 0) {
		return [NSString stringWithFormat:@"%i %@, %i %@ %@ %i %@",// "HH hours, MM minutes and SS seconds"
				hours, hoursString,
				minutes, minutesString,
				NSLocalizedString(@"and", nil),
				seconds, secondsString];
	} else {
		return [NSString stringWithFormat:@"%i %@, %i %@, %i %@ %@ %i %@",// "DD days, HH hours, MM minutes and SS seconds"
				days, daysString,
				hours, hoursString,
				minutes, minutesString,
				NSLocalizedString(@"and", nil),
				seconds, secondsString];
	}
}

- (NSArray *)accessibilityElements
{
	if (!accessibilityElements) {
		NSMutableArray * allAccessibilityElements = [[NSMutableArray alloc] initWithCapacity:3];
		
		// Main countdown view (all labels for days, hours, minutes and seconds)
		UIAccessibilityElement * accessibilityElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
		accessibilityElement.accessibilityFrame = CGRectMake(30., 40., 260., 350.);
		accessibilityElement.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
		accessibilityElement.accessibilityLabel = [self accessibleCurrentDate];
		[allAccessibilityElements addObject:accessibilityElement];
		
		// Name Label
		accessibilityElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
		accessibilityElement.accessibilityFrame = CGRectOffset(nameLabel.frame, 0., 20.);
		accessibilityElement.accessibilityLabel = self.countdown.name;
		[allAccessibilityElements addObject:accessibilityElement];
		
		// Settings button
		accessibilityElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
		accessibilityElement.accessibilityFrame = CGRectOffset(infoButton.frame, 0., 20.);
		accessibilityElement.accessibilityTraits = UIAccessibilityTraitButton;
		accessibilityElement.accessibilityLabel = NSLocalizedString(@"Current countdown settings", nil);
		accessibilityElement.accessibilityHint = NSLocalizedString(@"Go to countdown settings", nil);
		[allAccessibilityElements addObject:accessibilityElement];
		
		accessibilityElements = (NSArray *)allAccessibilityElements;
	}
	
	return accessibilityElements;
}

- (BOOL)isAccessibilityElement
{
	return NO;
}

- (NSInteger)accessibilityElementCount
{
	return 3; // The main countdown view, the name label and the settings button
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	UIAccessibilityElement * element = [[self accessibilityElements] objectAtIndex:index];
	if (index == 0) {
		element.accessibilityLabel = [self accessibleCurrentDate];
		if (UIInterfaceOrientationIsLandscape(orientation)) {
			element.accessibilityFrame = CGRectMake(120., 40., 80., 400.);
		} else {
			if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
				element.accessibilityFrame = CGRectMake(20., 90., 280., 350.);
			} else {
				element.accessibilityFrame = CGRectMake(20., 50., 280., 350.);
			}
		}
	} else if (index == 1) {
		if (UIInterfaceOrientationIsLandscape(orientation)) {
			if (orientation == UIInterfaceOrientationLandscapeLeft) {
				element.accessibilityFrame = CGRectMake(30., 90., 30., 300.);
			} else {
				element.accessibilityFrame = CGRectMake(260., 90., 30., 300.);
			}
		} else {
			if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
				element.accessibilityFrame = CGRectMake(70., 45., 180., 30.);
			} else {
				element.accessibilityFrame = CGRectOffset(nameLabel.frame, 0., 20.);
			}
		}
	} else {
		if (UIInterfaceOrientationIsLandscape(orientation)) {
			if (orientation == UIInterfaceOrientationLandscapeLeft) {
				element.accessibilityFrame = CGRectMake(30., 440., 30., 30.);
			} else {
				element.accessibilityFrame = CGRectMake(260., 10., 30., 30.);
			}
		} else {
			if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
				element.accessibilityFrame = CGRectMake(20., 45., 30., 30.);
			} else {
				element.accessibilityFrame = CGRectOffset(infoButton.frame, 0., 20.);
			}
		}
	}
	
	return element;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [accessibilityElements indexOfObject:element];
}


NSString * stringFormat(unsigned int value, BOOL addZero)
{
	if (value <= 0)
		return (addZero)? @"00" : @"0";
	
	if (addZero && value < 10) {
		return [NSString stringWithFormat:@"0%i", value];
	} else {
		return [NSString stringWithFormat:@"%i", value];
	}
}

- (void)setStyle:(CountdownPageViewStyle)aStyle
{
	FontDescription * fontDescription = nil;
	switch (aStyle) {
		case CountdownPageViewStyleDefault: {
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = [UIColor whiteColor];
			fontDescription.shadowColor = [UIColor blackColor];
			fontDescription.shadowOffset = CGSizeMake(0., -2.);
			
			[self setLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont systemFontOfSize:0.];
			fontDescription.textColor = [UIColor whiteColor];
			
			[self setDescriptionLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = [UIColor whiteColor];
			
			[self setNameFontDescription:fontDescription];
			
			
			self.backgroundImageName = @"background1";
			self.landscapeBackgroundImageName = @"background1_landscape";
		}
			break;
		case CountdownPageViewStyleLCD: {
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"DBLCDTempBlack" size:0.];
			fontDescription.textColor = [UIColor colorWithWhite:0. alpha:0.6];
			
			[self setLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont systemFontOfSize:0.];
			fontDescription.textColor = [UIColor colorWithWhite:0. alpha:0.6];
			
			[self setDescriptionLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = [UIColor colorWithWhite:0. alpha:0.6];
			
			[self setNameFontDescription:fontDescription];
			
			
			self.backgroundImageName = @"background2";
			self.landscapeBackgroundImageName = @"background2_landscape";
		}
			break;
		case CountdownPageViewStyleBoard: {
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:0.];
			fontDescription.textColor = [UIColor blackColor];
			
			[self setLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:0.];
			fontDescription.textColor = [UIColor blackColor];
			
			[self setDescriptionLabelFontDescription:fontDescription];
			
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = [UIColor blackColor];
			
			[self setNameFontDescription:fontDescription];
			
			
			self.backgroundImageName = @"background3";
			self.landscapeBackgroundImageName = @"background3_landscape";
		}
			break;
		case CountdownPageViewStyleLetter: {
			/* Numbers Font Description */
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"Courier" size:0.];
			fontDescription.textColor = [UIColor colorWithRed:0. green:0. blue:0.2 alpha:1.];
			
			[self setLabelFontDescription:fontDescription];
			
			/* Legend Font Description */
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"Courier" size:0.];
			fontDescription.textColor = [UIColor colorWithRed:0. green:0. blue:0.2 alpha:1.];
			
			[self setDescriptionLabelFontDescription:fontDescription];
			
			/* Name Font Description */
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = [UIColor colorWithRed:0. green:0. blue:0.2 alpha:1.];
			
			[self setNameFontDescription:fontDescription];
			
			
			self.backgroundImageName = @"background4";
			self.landscapeBackgroundImageName = @"background4_landscape";
		}
			break;
		case CountdownPageViewStyleTimes: {
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:0.];
			
			UIColor * color = [[UIColor alloc] initWithRed:0.392 green:0.192 blue:0. alpha:1.];
			fontDescription.textColor = color;
			
			fontDescription.shadowColor = [UIColor colorWithWhite:1. alpha:0.5];
			fontDescription.shadowOffset = CGSizeMake(0., 1.);
			
			[self setLabelFontDescription:fontDescription];
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:0.];
			fontDescription.textColor = color;
			[self setDescriptionLabelFontDescription:fontDescription];
			
			
			fontDescription = [[FontDescription alloc] init];
			fontDescription.font = [UIFont boldSystemFontOfSize:0.];
			fontDescription.textColor = color;
			
			[self setNameFontDescription:fontDescription];
			
			
			self.backgroundImageName = @"background5";
			self.landscapeBackgroundImageName = @"background5_landscape";
		}
			break;
		default:
			self.style = CountdownPageViewStyleDefault;
			break;
	}
	
	style = aStyle;
	
	[self unload];// Force unload,
	[self load];// Then reload to refresh content
}

- (void)setLabelFontDescription:(FontDescription *)fontDescription
{
	[daysLabel setFrontDescription:fontDescription];
	[hoursLabel setFrontDescription:fontDescription];
	[minutesLabel setFrontDescription:fontDescription];
	[secondsLabel setFrontDescription:fontDescription];
	
	// Landscape
	[timeLabelLanscape setFrontDescription:fontDescription];
}

- (void)setDescriptionLabelFontDescription:(FontDescription *)fontDescription
{
	[daysDescriptionLabel setFrontDescription:fontDescription];
	[hoursDescriptionLabel setFrontDescription:fontDescription];
	[minutesDescriptionLabel setFrontDescription:fontDescription];
	[secondsDescriptionLabel setFrontDescription:fontDescription];
}

- (void)setNameFontDescription:(FontDescription *)fontDescription
{
	[nameLabel setFrontDescription:fontDescription];
	
	// Landscape
	[nameLabelLandscape setFrontDescription:fontDescription];
}

- (void)setCountdown:(Countdown *)aCountdown
{
	countdown = aCountdown;
	
	nameLabel.text = countdown.name;
	nameLabelLandscape.text = countdown.name;
	
	self.style = countdown.style;
}

- (void)setInfoButtonType:(UIButtonType)type // @TODO: Remove if unused
{
	if (type != UIButtonTypeInfoDark && type != UIButtonTypeInfoLight)
		return;
	
#define kPortraitButtonTag 1234
#define kLandscapeButtonTag 2345
	
	if (infoButtonType != type) {
		[[self viewWithTag:kPortraitButtonTag] removeFromSuperview];
		[[self viewWithTag:kLandscapeButtonTag] removeFromSuperview];
	}
	
	// Portrait Button
	if (![self viewWithTag:kPortraitButtonTag]) {
		UIButton * anInfoButton = [UIButton buttonWithType:type];
		anInfoButton.tag = kPortraitButtonTag;
		
		NSArray * targets = [[infoButton allTargets] allObjects];
		if (targets.count > 0) {
			NSObject * target = [targets objectAtIndex:0];
			NSArray * actions = [infoButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
			for (NSString * actionString in actions) {
				SEL selector = NSSelectorFromString(actionString);
				[anInfoButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
			}
		}
		
		anInfoButton.frame = infoButton.frame;
		[infoButton removeFromSuperview];
		[self addSubview:anInfoButton];
	}
	
	// Landscape Button
	if (![self viewWithTag:kLandscapeButtonTag]) {
		UIButton * anInfoButton = [UIButton buttonWithType:type];
		anInfoButton.tag = kLandscapeButtonTag;
		
		NSArray * targets = [[infoButton allTargets] allObjects];
		if (targets.count > 0) {
			NSObject * target = [targets objectAtIndex:0];
			NSArray * actions = [infoButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
			for (NSString * actionString in actions) {
				SEL selector = NSSelectorFromString(actionString);
				[anInfoButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
			}
		}
		
		anInfoButton.frame = infoButtonLandscape.frame;
		[infoButtonLandscape removeFromSuperview];
		[self addSubview:anInfoButton];
	}
	
	infoButtonType = type;
}

- (void)setOrientation:(UIInterfaceOrientation)newOrientation
{
	orientation = newOrientation;
	
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		_contentView.hidden = NO;
		_contentViewLandscape.hidden = YES;
	} else if (UIInterfaceOrientationIsLandscape(orientation)) {
		
		/* Load Landscape Nib if it is not done yet */
		if (!_contentViewLandscape) {
			[[CountdownPageView landscapeNib] instantiateWithOwner:self options:nil];
			NSDebugLog(@"Instantiate landscapeNib.");
			
			[self addSubview:_contentViewLandscape];
			self.countdown = self.countdown;// Force UI reload
			
			/* Force "infoButtonLandscape" to have same actions as "infoButton" */
			id target = infoButton.allTargets.anyObject;
			SEL action = NSSelectorFromString([[infoButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside] lastObject]);
			[infoButtonLandscape addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
		}
		
		_contentView.hidden = YES;
		_contentViewLandscape.hidden = NO;
	}
	
	[self update];
}

- (void)update
{
	NSDate * date = countdown.endDate;
	NSTimeInterval timeInterval = [date timeIntervalSinceNow];
	timeInterval = (timeInterval > 0.)? timeInterval: 0.;// Clip timeInterval to zero
	
	NSUInteger days = timeInterval / (24. * 60. * 60.);
	timeInterval -= (days * 24 * 60 * 60);
	
	NSUInteger hours = timeInterval / (60. * 60.);
	timeInterval -= (hours * 60 * 60);
	
	NSUInteger minutes = timeInterval / 60.;
	timeInterval -= (minutes * 60);
	
	NSUInteger seconds = timeInterval;
	
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		
		if (days > 0) {// If days, show days:hours:minutes:seconds
			timeLabelLanscape.text = [NSString stringWithFormat:@"%@:%@:%@:%@", stringFormat(days, NO), stringFormat(hours, YES), stringFormat(minutes, YES), stringFormat(seconds, YES)];
		} else {// Else, just show hours:minutes:seconds
			timeLabelLanscape.text = [NSString stringWithFormat:@"%@:%@:%@", stringFormat(hours, NO), stringFormat(minutes, YES), stringFormat(seconds, YES)];
		}
		
	} else {
		
		CGFloat offsetY = 0.;
		if (days > 0) {
			daysLabel.hidden = NO;
			daysDescriptionLabel.hidden = NO;
		} else {
			daysLabel.hidden = YES;// Hide days stuff
			daysDescriptionLabel.hidden = YES;
			
			offsetY = -30.;
		}
		
		[hoursLabel setY:hoursLabelY + offsetY];
		[hoursDescriptionLabel setY:hoursDescriptionLabelY + offsetY];
		
		[minutesLabel setY:minutesLabelY + offsetY];
		[minutesDescriptionLabel setY:minutesDescriptionLabelY + offsetY];
		
		[secondsLabel setY:secondsLabelY + offsetY];
		[secondsDescriptionLabel setY:secondsDescriptionLabelY + offsetY];
		
		if (days > 0) {
			daysLabel.text = [NSString stringWithFormat:@"%@", stringFormat(days, NO)];
			hoursLabel.text = [NSString stringWithFormat:@":%@", stringFormat(hours, YES)];
		} else {
			hoursLabel.text = [NSString stringWithFormat:@"%@", stringFormat(hours, YES)];
		}
		
		minutesLabel.text = [NSString stringWithFormat:@":%@", stringFormat(minutes, YES)];
		secondsLabel.text = [NSString stringWithFormat:@":%@", stringFormat(seconds, YES)];
		
		daysDescriptionLabel.text = (days > 1)? NSLocalizedString(@"DAYS_MANY", nil):
		((days == 1)? NSLocalizedString(@"DAY_ONE", nil): NSLocalizedString(@"DAYS_ZERO", nil));
		hoursDescriptionLabel.text = (hours > 1)? NSLocalizedString(@"HOURS_MANY", nil):
		((hours == 1)? NSLocalizedString(@"HOUR_ONE", nil): NSLocalizedString(@"HOURS_ZERO", nil));
		minutesDescriptionLabel.text = (minutes > 1)? NSLocalizedString(@"MINUTES_MANY", nil):
		((minutes == 1)? NSLocalizedString(@"MINUTE_ONE", nil): NSLocalizedString(@"MINUTES_ZERO", nil));
		secondsDescriptionLabel.text = (seconds > 1)? NSLocalizedString(@"SECONDS_MANY", nil):
		((seconds == 1)? NSLocalizedString(@"SECOND_ONE", nil): NSLocalizedString(@"SECONDS_ZERO", nil));
	}
}

- (IBAction)showSettings:(id)sender
{
	/* Show settings */
	if ([self.delegate respondsToSelector:@selector(pageViewWillShowSettings:)])
		[self.delegate pageViewWillShowSettings:self];
}

- (void)showDescription:(BOOL)show animated:(BOOL)animated
{
	/* 0s for unanimated, 0.2s to show, 0.5s to hide */
	NSTimeInterval duration = (animated) ? ((show) ? 0.2 : 0.5) : 0.;
	[UIView animateWithDuration:duration
						  delay:0.
						options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn)
					 animations:^{
						 daysDescriptionLabel.alpha = (show)? 1.: 0.;
						 hoursDescriptionLabel.alpha = (show)? 1.: 0.;
						 minutesDescriptionLabel.alpha = (show)? 1.: 0.;
						 secondsDescriptionLabel.alpha = (show)? 1.: 0.;
					 }
					 completion:NULL];
	
	if (show) {// Re-hide description after 5 secondes
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performHideDescription) object:nil];
		[self performSelector:@selector(performHideDescription) withObject:nil afterDelay:kHideDescriptionDelay];
	}
}

- (void)performHideDescription
{
	[self showDescription:NO animated:YES];
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
#pragma Page Resources Management

- (void)load
{
	if (!_loaded) {// Then reload it
		backgroundImageView.image = [UIImage imageNamed:self.backgroundImageName];
		backgroundImageViewLandscape.image = [UIImage imageNamed:self.landscapeBackgroundImageName];
		
		_loaded = YES;
	}
}

- (void)unload
{
	if (_loaded) {
		backgroundImageView.image = nil;
		backgroundImageViewLandscape.image = nil;
		
		_loaded = NO;
	}
}

#pragma mark -
#pragma Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<PageView: 0x%p; frame = (%.1f %.1f; %.1f %.1f); alpha = %.1f; layer = <CALayer: %@>>", self, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height, self.alpha, _contentView.layer];
}


- (void)handleSingleTap
{
	if ([delegate respondsToSelector:@selector(viewDidSingleTap:)])
		[delegate viewDidSingleTap:self];
}

- (void)handleDoubleTap
{
	//[infoButton sendActionsForControlEvents:UIControlEventTouchUpInside]; // @TODO: Remove if unused
	
	if ([delegate respondsToSelector:@selector(viewDidDoubleTap:)])
		[delegate viewDidDoubleTap:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = [touches anyObject];
	
	if (touch.tapCount == 1)
		[self performSelector:@selector(handleSingleTap) withObject:nil afterDelay:kDoubleTapDelay];
	else if (touch.tapCount == 2) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSingleTap) object:nil];
		[self handleDoubleTap];
	}
}

- (void)dealloc
{
	self.countdown = nil;
}


@end
