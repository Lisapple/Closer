//
//  UINavigationController+additions.m
//  Closer
//
//  Created by Maxime Leroy on 2/1/13.
//
//

#import "UINavigationController+additions.h"

@implementation UINavigationController (additions)

- (BOOL)disablesAutomaticKeyboardDismissal
{
	return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return (TARGET_IS_IPAD()) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

@end
