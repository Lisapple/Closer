//
//  SectionCalendarTableViewCell.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface _InternalSectionCalendarView : UIView
{
	CGColorRef CGColor;
}

@property (nonatomic, assign) CGColorRef CGColor;

@end

@interface SectionCalendarTableViewCell : UITableViewCell
{
	CGColorRef CGColor;
}

@property (nonatomic, assign) CGColorRef CGColor;

@end
