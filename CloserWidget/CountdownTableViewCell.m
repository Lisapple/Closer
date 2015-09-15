//
//  CountdownTableViewCell.m
//  Closer
//
//  Created by Max on 31/01/15.
//
//

#import "CountdownTableViewCell.h"
#import "NSArray+addition.h"

@interface CountdownTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel * label;
@property (strong, nonatomic) UIView * progressionView;

@end

@implementation CountdownTableViewCell

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
    long minutes = seconds / 60; //seconds -= minutes * 60;
    
    NSInteger numberOfComponents = (days > 0) + (hours > 0) + (minutes > 0);
    NSMutableArray * components = [[NSMutableArray alloc] initWithCapacity:4];
    if (numberOfComponents >= 2) {
        if (days) [components addObject:[NSString stringWithFormat:@"%ld %@", days, (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)]];
        if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@", hours, (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)]];
        if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@", minutes, NSLocalizedString(@"min", nil)]];
    } else {
        if (days) [components addObject:[NSString stringWithFormat:@"%ld %@", days, (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)]];
        if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@", hours, (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)]];
        if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@", minutes, (minutes > 1) ? NSLocalizedString(@"minutes", nil) : NSLocalizedString(@"minute", nil)]];
    }
    
    return [components componentsJoinedByString:@", " withLastJoin:NSLocalizedString(@" and ", nil)]; // "12 minutes and 34 seconds", "12 days, 34 hours and 56 min"
}

- (void)update
{
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[_name stringByAppendingString:@"\t"]
                                                                                attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:self.endDateDescription
                                                                   attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1. alpha:0.2] }]];
    _label.attributedText = string;
    
    double seconds = _endDate.timeIntervalSinceNow;
    CGRect frame = _progressionView.frame;
    if (seconds > 0.) {
		CGFloat progression = 1. - ((double)log(seconds / (60. * M_E)) - 1.) / 14.;
        frame.size.width = (self.frame.size.width - 8.) * progression;
        frame.origin.y = self.frame.size.height - 1.;
    } else {
        frame.size.width = 0.;
    }
    _progressionView.frame = frame;
}

@end
