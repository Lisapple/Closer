//
//  UILabel+addition.m
//  Closer
//
//  Created by Max on 10/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "UILabel+addition.h"


@implementation UILabel (addition)

- (void)setFrontDescription:(FontDescription *)fontDescription
{
	self.font = [UIFont fontWithName:fontDescription.font.fontName size:self.font.pointSize];
	
	self.textColor = fontDescription.textColor;
	
	self.shadowColor = fontDescription.shadowColor;
	self.shadowOffset = fontDescription.shadowOffset;
}

@end
