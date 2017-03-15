//
//  PasswordTextField.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "PasswordLabel.h"

@implementation PasswordLabel

- (void)drawRect:(CGRect)rect
{
	UIImage * image = [UIImage imageNamed:@"password-field-background"];
	[[image stretchableImageWithLeftCapWidth:image.size.width / 2
								topCapHeight:image.size.height / 2] drawInRect:rect];
	[super drawRect:rect];
}

@end
