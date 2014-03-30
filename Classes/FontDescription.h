//
//  FontDescription.h
//  Closer
//
//  Created by Max on 10/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FontDescription : NSObject
{
	UIFont * font;
	UIColor * textColor, * shadowColor;
	CGSize shadowOffset;
}

@property (nonatomic, strong) UIFont * font;
@property (nonatomic, strong) UIColor * textColor, * shadowColor;
@property (nonatomic, assign) CGSize shadowOffset;

@end
