//
//  TimerTableViewCell.m
//  Closer
//
//  Created by Max on 11/02/15.
//
//

#import "TimerTableViewCell.h"
#import "Utilities.h"

#import "NSArray+addition.h"
#import "NSMutableAttributedString+addition.h"

@interface TimerTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel * label;
@property (strong, nonatomic) UIView * progressionView;
@property (strong, nonatomic, nonnull) NSLayoutConstraint * widthConstraint;

@end

@implementation TimerTableViewCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	CGRect frame = CGRectMake(0., self.frame.size.height - 1., self.frame.size.width - 8., 1. / [UIScreen mainScreen].scale);
	if (!IS_IOS10_OR_MORE) {
		UIVisualEffect * effect = [UIVibrancyEffect notificationCenterVibrancyEffect];
		UIVisualEffectView * visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
		visualEffectView.tintColor = [UIColor clearColor];
		visualEffectView.frame = self.bounds;
		visualEffectView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		
		
		UIView * separator = [[UIView alloc] initWithFrame:frame];
		separator.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
		separator.backgroundColor = [UIColor whiteColor];
		[visualEffectView.contentView addSubview:separator];
		[self addSubview:visualEffectView];
	}
	
	_progressionView = [[UIView alloc] init];
	_progressionView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:_progressionView];
	_widthConstraint = [NSLayoutConstraint constraintWithItem:_progressionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
													   toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:0];
	[self addConstraints:@[ [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
															toItem:_progressionView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
							[NSLayoutConstraint constraintWithItem:_progressionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
															toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:1],
							_widthConstraint]];
}

- (void)setName:(NSString *)name
{
	_name = name;
	[self update];
}

- (void)setDuration:(NSInteger)duration
{
	_duration = duration;
	[self update];
}

- (void)setRemaining:(NSInteger)remaining
{
	_remaining = remaining;
	[self update];
}

- (NSString *)formattedDuration
{
	double seconds = _remaining;
	if (seconds <= 0)
		return NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil);
	
	double days = seconds / (24. * 60. * 60.);
	if (floor(days) >= 2.)
		return [NSString stringWithFormat:@"%d %@", (int)ceil(days), (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)];
	
	double hours = seconds / (60. * 60.);
	if (floor(hours) >= 2.)
		return [NSString stringWithFormat:@"%d %@", (int)ceil(hours), (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)];
	
	double minutes = seconds / 60.;
	if (floor(minutes) >= 2.)
		return [NSString stringWithFormat:@"%d %@", (int)ceil(minutes), NSLocalizedString(@"min", nil)];
	
	return [NSString stringWithFormat:@"%d %@", (int)ceil(seconds), NSLocalizedString(@"sec", nil)];
}

- (void)update
{
	UIColor * textColor = IS_IOS10_OR_MORE ? [UIColor darkTextColor] : [UIColor lightTextColor];
	
	NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[_name stringByAppendingString:@"\n"]
																				attributes:@{ NSForegroundColorAttributeName : textColor }];
	[string appendString:self.formattedDuration attributes:@{ NSForegroundColorAttributeName : [textColor colorWithAlphaComponent:0.75] }];
	_label.attributedText = string;
	
	double seconds = _remaining;
	if (seconds > 0.) {
		CGFloat progression = 1. - (_remaining / (CGFloat)_duration);
		_widthConstraint.constant = (self.frame.size.width - 8.) * progression;
	} else
		_widthConstraint.constant = 0.;
	
	_progressionView.backgroundColor = textColor;
}

@end
