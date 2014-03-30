//
//  DurationPickerTableViewCell.m
//  Closer
//
//  Created by Maxime Leroy on 7/5/13.
//
//

#import "DurationPickerTableViewCell.h"

@implementation DurationPickerTableViewCell

@synthesize label = _label;
@synthesize pickerView = _pickerView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
		
		CGRect rect = CGRectMake(0., 10., self.frame.size.width, 20.);
		_label = [[UILabel alloc] initWithFrame:rect];
		_label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_label.backgroundColor = [UIColor clearColor];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.font = [UIFont boldSystemFontOfSize:17.];
		[self.contentView addSubview:_label];
		
		rect = CGRectMake(0., 40., self.frame.size.width, 42);
		_pickerView = [[DurationPickerView alloc] initWithFrame:rect];
		_pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:_pickerView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
