//
//  SongTableViewCell.m
//  Closer
//
//  Created by Max on 3/9/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CheckTableViewCell.h"


@implementation CheckTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryView = nil;
	}
	return self;
}

#if 0
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* At every change of color, store the new one (as simple reference) */
	if ([keyPath isEqualToString:@"textColor"]) {
		UILabel * label = (UILabel *)object;
		textLabelColor = label.textColor;
	}
}

- (UILabel *)textLabel
{
	UILabel * textLabel = [super textLabel];
	
	/* Add observer to notify when "textLabel.textColor" change to store the color changement, the "textLabelColor" ivar will contains the color for "textLabel" set by the 'using' of the subclass. */
	if (![textLabel observationInfo])// If we don't observe "textLabel", do it.
		[textLabel addObserver:self forKeyPath:@"textColor" options:NSKeyValueObservingOptionNew context:NULL];
	
	return textLabel;
}
#endif

- (void)setAccessoryType:(UITableViewCellAccessoryType)aType
{
	if (aType == UITableViewCellAccessoryCheckmark) {
		
	} else if (aType == UITableViewCellAccessoryNone) {
		self.accessoryView = nil;
	}
	
	[super setAccessoryType:aType];
}

- (void)setAccessoryViewSelected:(BOOL)selected animated:(BOOL)animated
{
	float delay = (animated)? 0.3: 0.;
	
	if (self.selectionStyle != UITableViewCellSelectionStyleNone) {// No color change with UITableViewCellSelectionStyleNone
		if (selected) {
			
			self.textLabel.textColor = [UIColor whiteColor];
			
#if 0
			/* As we observe "textLabel" change color, we don't want the whiteColor set interferate with "textLabelColor" ivar change... */
			
			UILabel * label = self.textLabel;// Create a "label" local var to not call "self.textLabel" after we remove observer
			
			if ([label observationInfo])
				[label removeObserver:self forKeyPath:@"textColor"];// ... remove observer...
			
			/* NOTE: Don't call "self.textLabel" now, we don't have any observer on it from now, call "self.textLabel" will create one and notify from current changement. Use the local "label" variable instead */
			label.textColor = [UIColor whiteColor];// Change color (white is the highlight/select color for textLabel)
			
			[label addObserver:self forKeyPath:@"textColor" options:NSKeyValueObservingOptionNew context:NULL];// ... and re-add observer to catch textColor changes taht are not from the method
#endif
		} else {
			[self.textLabel performSelector:@selector(setTextColor:)
								 withObject:[UIColor blackColor]
								 afterDelay:delay];
		}
	}
	
	if (self.accessoryType == UITableViewCellAccessoryNone) {
		
		if (selected) {
			UIImageView * accessoryImageView = nil;
			accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_selected"]];
			self.accessoryView = accessoryImageView;
		} else {
			self.accessoryView = nil;
		}
		
	} else if (self.accessoryType == UITableViewCellAccessoryCheckmark) {
		/* When we using performSelector:withObject:afterDelay:, this use the current run loop to call the selector even if no delay have been set. In this case, iOS set the accessoryView with a "check" image before we set the accessoryView with nothing (to remove the "check" image). With performSelector:withObject:afterDelay: and the run loop, the system could set the "check" image after we set it with nothing.
		 So, to prevent this overflow effect, just call setAccessoryView: directly if no delay have been set. */
		if (delay) {
			[self performSelector:@selector(setAccessoryView:)
					   withObject:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]]
					   afterDelay:delay];
		} else {
			UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]];
			self.accessoryView = imageView;
		}
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

- (void)dealloc
{
	self.accessoryView = nil;
	
	/*
	[textLabelColor release];
	
	if (![self.textLabel observationInfo])
		[self.textLabel removeObserver:self forKeyPath:@"textColor"];
	*/
	
}


@end
