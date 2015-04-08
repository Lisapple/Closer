//
//  NotificationHelper.m
//  Closer
//
//  Created by Max on 05/04/15.
//
//

#import <Foundation/Foundation.h>
#import "Closer WatchKit Extension-Bridging-Header.h"

static void countdownsSynchronised(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	// If center is a Darwin notification center, |object| and |userInfo| are ignored.
	[[NSNotificationCenter defaultCenter] postNotificationName:(__bridge NSString *)name
														object:(__bridge id)object
													  userInfo:(__bridge NSDictionary *)userInfo];
}

@implementation NotificationHelper

+ (instancetype)sharedInstance
{
	static NotificationHelper * helper = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		helper = [[NotificationHelper alloc] init];
	});
	return helper;
}

- (void)startObservingNotificationName:(NSString *)name
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),
									countdownsSynchronised, (__bridge CFStringRef)name, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)stopObservingNotificationName:(NSString *)name
{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),
									   (__bridge CFStringRef)name, NULL);
}

@end