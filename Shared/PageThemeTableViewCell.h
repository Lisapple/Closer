//
//  PageThemeTableViewCell.h
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CheckTableViewCell.h"

@interface PageThemeTableViewCell : CheckTableViewCell
{
	UIImageView * imageView;
	UILabel * textLabel;
}

@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) UILabel * textLabel;

@end
