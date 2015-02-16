//
//  NetworkStatus.h
//  Closer
//
//  Created by Max on 09/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#define kNetworkStatusDidChangeNotification NetworkStatusDidChangeNotification
extern NSString * const NetworkStatusDidChangeNotification;

@interface NetworkStatus : NSObject

+ (BOOL)isConnected;
+ (void)startObserving;
+ (void)stopObserving;

@end
