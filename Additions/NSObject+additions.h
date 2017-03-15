//
//  NSObject+addition.h
//  Elsas Gone
//
//  Created by Max on 7/23/14.
//  Copyright (c) 2014 Lisacintosh. All rights reserved.
//

@interface NSObject (addition)

+ (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay;

@end
