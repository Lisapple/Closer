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
	[[NSNotificationCenter defaultCenter] postNotificationName:(__bridge NSString *)name object:nil];
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

+ (void(*)(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo))notif
{
	return countdownsSynchronised;
}

- (void)stopObservingNotificationName:(NSString *)name
{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),
									   (__bridge CFStringRef)name, NULL);
}

@end