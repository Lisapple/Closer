//
//  NSDate+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//


@interface NSDate(addition)

- (NSInteger)second;
- (NSInteger)minute;
- (NSString *)minuteString;
- (NSInteger)hour;

- (NSInteger)day;
- (NSInteger)month;
- (NSInteger)year;

- (NSString *)naturalTimeString;
- (NSString *)naturalDateString;

- (NSString *)rfc5545Format;
- (NSString *)SQLDateTime;

@end
