//
//  VCalendar.h
//  Closer
//
//  Created by Max on 08/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface VEvent : NSObject

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) NSString * summary, * message;
@property (nonatomic, copy, readonly) NSString * UUID;

+ (VEvent *)eventFromCountdown:(Countdown *)countdown;

- (instancetype)initWithUUID:(NSString *)seed NS_DESIGNATED_INITIALIZER;

@end

@interface VCalendar : NSObject

- (instancetype)initWithVersion:(NSString *)versionString NS_DESIGNATED_INITIALIZER;

- (void)addEvent:(VEvent *)event;
- (void)removeEvent:(VEvent *)event;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;

@end
