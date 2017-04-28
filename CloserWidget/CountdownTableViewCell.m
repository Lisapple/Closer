//
//  CountdownTableViewCell.m
//  Closer
//
//  Created by Max on 31/01/15.
//
//

#import "CountdownTableViewCell.h"
#import "Utilities.h"

#import "NSArray+addition.h"
#import "NSMutableAttributedString+addition.h"

@interface CountdownTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel * label;
@property (strong, nonatomic) UIView * progressionView;
@property (strong, nonatomic, nonnull) NSLayoutConstraint * widthConstraint;

@end

@implementation CountdownTableViewCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if (!IS_IOS10_OR_MORE) {
IGNORE_DEPRECATION_BEGIN
		UIVisualEffect * effect = [UIVibrancyEffect notificationCenterVibrancyEffect];
		UIVisualEffectView * visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
		visualEffectView.tintColor = [UIColor clearColor];
		visualEffectView.frame = self.bounds;
		visualEffectView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
IGNORE_DEPRECATION_END
		
		const CGRect frame = CGRectMake(0., self.frame.size.height - 1., self.frame.size.width - 8., 1. / [UIScreen mainScreen].scale);
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

- (void)setEndDate:(NSDate *)endDate
{
	_endDate = endDate;
	[self update];
}

- (NSString *)endDateDescription
{
	long seconds = _endDate.timeIntervalSinceNow;
	if (seconds <= 0)
		return NSLocalizedString(@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE", nil);
	
	long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
	long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
	long minutes = seconds / 60;
	
	NSInteger numberOfComponents = (days > 0) + (hours > 0) + (minutes > 0);
	NSMutableArray * components = [[NSMutableArray alloc] initWithCapacity:4];
	if (days) [components addObject:[NSString stringWithFormat:@"%ld %@", days, NSLocalizedString( (days > 1) ? @"days" : @"day", nil)]];
	if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@", hours, NSLocalizedString( (hours > 1) ? @"hours" : @"hour", nil)]];
	if (minutes) {
		if (numberOfComponents >= 2) {
			[components addObject:[NSString stringWithFormat:@"%ld %@", minutes, NSLocalizedString(@"min", nil)]];
		} else {
			[components addObject:[NSString stringWithFormat:@"%ld %@", minutes, NSLocalizedString( (minutes > 1) ? @"minutes" : @"minute", nil)]];
		}
	}
	return [components componentsJoinedByString:@", " withLastJoin:NSLocalizedString(@" and ", nil)]; // "1 hour and 12 minutes", "12 days, 34 hours and 56 min"
}

- (void)update
{
	UIColor * textColor = IS_IOS10_OR_MORE ? [UIColor darkTextColor] : [UIColor lightTextColor];
	
	NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[_name stringByAppendingString:@"\n"]
																				attributes:@{ NSForegroundColorAttributeName : textColor }];
	[string appendString:self.endDateDescription attributes:@{ NSForegroundColorAttributeName : [textColor colorWithAlphaComponent:0.75] }];
	_label.attributedText = string;
	
	double seconds = _endDate.timeIntervalSinceNow;
	if (seconds > 0.) {
		CGFloat progression = 1. - ((double)log(seconds / (60. * M_E)) - 1.) / 14.;
		_widthConstraint.constant = (self.frame.size.width - 8.) * progression;
	} else
		_widthConstraint.constant = 0.;
	
	_progressionView.backgroundColor = textColor;
}

@end
