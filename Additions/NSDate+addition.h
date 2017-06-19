//
//  NSDate+addition.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSDate(addition)

- (NSInteger)year;

- (NSInteger)daysFromNow;

- (NSString *)naturalTimeString;
- (NSString *)naturalDateString;

- (NSString *)rfc5545Format;
- (NSString *)SQLDateTime;

- (NSString * _Nullable)localizedDescription;

@end

NS_ASSUME_NONNULL_END
