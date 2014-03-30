//
//  UITableView+addition.h
//  Closer
//
//  Created by Max on 3/8/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITableView (addition)

@property (nonatomic, strong) NSString * footerText;

- (void)setFooterText:(NSString *)text;

@end
