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

@end

@implementation TimerTableViewCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIVisualEffect * effect = [UIVibrancyEffect notificationCenterVibrancyEffect];
    UIVisualEffectView * visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    visualEffectView.tintColor = [UIColor clearColor];
    visualEffectView.frame = self.bounds;
    visualEffectView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    CGRect frame = CGRectMake(0., self.frame.size.height - 1., self.frame.size.width - 8., 1. / [UIScreen mainScreen].scale);
    UIView * separator = [[UIView alloc] initWithFrame:frame];
    separator.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    separator.backgroundColor = [UIColor whiteColor];
    [visualEffectView.contentView addSubview:separator];
    [self addSubview:visualEffectView];
    
    frame.size.height = 1.;
    _progressionView = [[UIView alloc] initWithFrame:frame];
    _progressionView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_progressionView];
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
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[_name stringByAppendingString:@" "]
                                                                                attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:self.formattedDuration
                                                                   attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:0.75 alpha:1] }]];
    _label.attributedText = string;
    
    double seconds = _remaining;
    CGRect frame = _progressionView.frame;
    if (seconds > 0.) {
        frame.size.width = (self.frame.size.width - 8.) * (1. - (_remaining / (float)_duration));
        frame.origin.y = self.frame.size.height - 1.;
    } else {
        frame.size.width = 0.;
    }
    _progressionView.frame = frame;
}

@end
