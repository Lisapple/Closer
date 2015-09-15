//
//  VCalendar.h
//  Closer
//
//  Created by Max on 08/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VEvent : NSObject
{
	NSDate * startDate;
	NSTimeInterval duration;
	NSString * summary, * description;
	NSString * UUID;
}

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) NSString * summary, * description;
@property (nonatomic, readonly) NSString * UUID;

+ (VEvent *)eventFromCountdown:(Countdown *)countdown;

- (instancetype)initWithUUID:(NSString *)seed NS_DESIGNATED_INITIALIZER;

@end

@interface VCalendar : NSObject
{
	NSString * version;
	
	NSMutableArray * events;
}

- (instancetype)initWithVersion:(NSString *)versionString NS_DESIGNATED_INITIALIZER;

- (void)addEvent:(VEvent *)event;
- (void)removeEvent:(VEvent *)event;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;

@end
