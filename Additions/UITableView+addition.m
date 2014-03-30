//
//  UITableView+addition.m
//  Closer
//
//  Created by Max on 3/8/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UITableView+addition.h"


@implementation UITableView (addition)

const NSInteger kFooterViewTag = 123;
const NSInteger kLabelTag = 456;

- (UILabel *)_footerLabel
{
	if (self.tableFooterView.tag != kFooterViewTag) {
		
		CGRect frame = CGRectMake(0., 0., self.bounds.size.width, 30.);
		UIView * view = [[UILabel alloc] initWithFrame:frame];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		view.autoresizesSubviews = YES;
		view.clipsToBounds = NO;
		view.tag = kFooterViewTag;
		view.backgroundColor = [UIColor clearColor];
		
		frame = CGRectMake(20., 0., self.bounds.size.width - 40., 30.);// Keep 20 px on left and right on label
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.tag = kLabelTag;
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.numberOfLines = 0;// Infinite number of line
		label.textColor = [UIColor darkGrayColor];
		label.textAlignment = UITextAlignmentCenter;
		label.font = [UIFont systemFontOfSize:15.];
		label.shadowColor = [UIColor colorWithWhite:1. alpha:0.7];
		label.shadowOffset = CGSizeMake(0., 1.);
		
		[view addSubview:label];
		
		self.tableFooterView = view;
	}
	
	return (UILabel *)[self.tableFooterView viewWithTag:kLabelTag];
}

- (NSString *)footerText // Implemented to provide a property for "setFooterText:"
{
	return nil;
}

- (void)setFooterText:(NSString *)text
{
	UILabel * footerLabel = (UILabel *)[self _footerLabel];
	footerLabel.text = text;
	
	CGSize size = [text sizeWithFont:footerLabel.font 
				   constrainedToSize:CGSizeMake(footerLabel.frame.size.width, INFINITY) 
					   lineBreakMode:footerLabel.lineBreakMode];
	
	CGRect frame = footerLabel.frame;
	footerLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
}

@end
