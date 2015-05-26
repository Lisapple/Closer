//
//  DeleteTableViewCell.m
//  Closer
//
//  Created by Max on 27/02/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "DeleteTableViewCell.h"

@implementation DeleteTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
		UIView * deleteView = [[UIView alloc] initWithFrame:self.frame];
		deleteView.backgroundColor = [UIColor redColor];
		self.backgroundView = deleteView;
		
		self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
