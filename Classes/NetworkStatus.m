//
//  NetworkStatus.m
//  Closer
//
//  Created by Max on 09/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NetworkStatus.h"

@implementation NetworkStatus

NSString * const NetworkStatusDidChangeNotification = @"NetworkStatusDidChangeNotification";

static SCNetworkReachabilityRef reachability = NULL;
static BOOL isObserving = NO;
static int _connected = -1;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		/* Create a default local address */
		struct sockaddr_in zeroAddress = { 0, 0, 0, { 0 }, { 0 } };
		zeroAddress.sin_len = sizeof(zeroAddress);
		zeroAddress.sin_family = AF_INET;
		
		reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
		
		SCNetworkReachabilityFlags flags = 0;
		SCNetworkReachabilityGetFlags(reachability, &flags);
		BOOL connected = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
		_connected = (int)connected;
	}
}

+ (BOOL)isConnected
{
	return (_connected == 1);
}

void NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	static int oldStatus = -1; // "-1" means no old status
	
	BOOL connected = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	_connected = (int)connected; // Change the "_connected" value before send the notification
	
	NSDebugLog(@"%@", (connected)? @"Connected": @"Not connected");
	
	if (oldStatus != (int)connected) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NetworkStatusDidChangeNotification
															object:@(connected)];
		oldStatus = (int)connected;
	}
}

+ (void)startObserving
{
	if (isObserving)
		[NetworkStatus stopObserving];
	
	if (!isObserving) {
		SCNetworkReachabilityContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
		SCNetworkReachabilitySetCallback(reachability, NetworkReachabilityCallBack, &context);
		
		SCNetworkReachabilitySetDispatchQueue(reachability, dispatch_get_main_queue());
		
		isObserving = YES;
	}
}

+ (void)stopObserving
{
	SCNetworkReachabilitySetDispatchQueue(reachability, NULL);
	isObserving = NO;
}

@end
