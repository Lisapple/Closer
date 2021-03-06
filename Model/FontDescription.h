//
//  FontDescription.h
//  Closer
//
//  Created by Max on 10/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@interface FontDescription : NSObject

@property (nonatomic, strong) UIFont * font;
@property (nonatomic, strong) UIColor * textColor, * shadowColor;
@property (nonatomic, assign) CGSize shadowOffset;

@end
