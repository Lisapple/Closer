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
	if (TARGET_IS_IOS7_OR_LATER())
		[[UIImage imageNamed:@"password-field-background-iOS7"] drawInRect:rect];
	else
		[[UIImage imageNamed:@"password-field-background"] drawInRect:rect];
	
	[super drawRect:rect];
}


@end
