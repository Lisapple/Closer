//
//  UIBarButtonItem+addition.m
//  Closer
//
//  Created by Max on 19/12/2016.
//
//

#import "UIBarButtonItem+addition.h"

@implementation UIBarButtonItem (addition)

+ (instancetype)flexibleSpace
{
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

@end
