//
//  MoreInfoButton.h
//  Closer
//
//  Created by Max on 4/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MoreInfoButton : UIView
{
	CGSize shadowOffset;
	
	@private
	UIButton * _infoButton, * _shadowInfoButton;
}

@property (nonatomic) CGSize shadowOffset;

// Private
@property (nonatomic, strong) UIButton * _infoButton, * _shadowInfoButton;

- (id)initWithFrame:(CGRect)frame;
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end
