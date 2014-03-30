//
//  PageThemeTableViewCell.m
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "PageThemeTableViewCell.h"

@implementation PageThemeTableViewCell

@synthesize imageView;
@synthesize textLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryView = nil;
		
		CGRect frame = CGRectMake(10., 2., 54., 65.);
		UIImageView * anImageView = [[UIImageView alloc] initWithFrame:frame];
		anImageView.contentMode = UIViewContentModeCenter;
		self.imageView = anImageView;
		
		[self.contentView addSubview:self.imageView];
		
		
		frame = CGRectMake(75., 0., 200., self.frame.size.height);
		UILabel * aTextLabel = [[UILabel alloc] initWithFrame:frame];
		aTextLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		aTextLabel.font = [UIFont boldSystemFontOfSize:16.];
		aTextLabel.opaque = NO;
		aTextLabel.backgroundColor = [UIColor clearColor];
		self.textLabel = aTextLabel;
		
		[self.contentView addSubview:self.textLabel];
		
	}
	return self;
}

- (UILabel *)textLabel
{
	[super textLabel];
	return textLabel;
}

/*
- (void)setAccessoryType:(UITableViewCellAccessoryType)aType
{
	if (aType == UITableViewCellAccessoryCheckmark) {
		
		UIImageView * accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]];
		self.accessoryView = accessoryImageView;
		[accessoryImageView release];
		
	} else if (aType == UITableViewCellAccessoryNone) {
		
		self.accessoryView = nil;
	}
	
	[super setAccessoryType:aType];
}

- (void)setAccessoryViewSelected:(BOOL)selected animated:(BOOL)animated
{
	if (selected)
		self.textLabel.textColor = [UIColor whiteColor];
	else {
		float delay = (animated)? 0.3: 0.;
		[self.textLabel performSelector:@selector(setTextColor:) withObject:[UIColor blackColor] afterDelay:delay];
	}
	
	if (self.accessoryType == UITableViewCellAccessoryCheckmark) {
		UIImageView * accessoryImageView = nil;
		
		if (selected)
			accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_selected"]];
		else {
			accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]];
		}
		
		self.accessoryView = accessoryImageView;
		[accessoryImageView release];
	}
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted)
		[self setAccessoryViewSelected:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	if (!selected)
		[self setAccessoryViewSelected:selected animated:animated];
}
*/

- (void)dealloc
{
	self.accessoryView = nil;
}


@end
