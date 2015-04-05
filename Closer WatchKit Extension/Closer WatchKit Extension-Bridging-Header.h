//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>

@interface NotificationHelper : NSObject

+ (instancetype)sharedInstance;
- (void)startObservingNotificationName:(NSString *)name;
- (void)stopObservingNotificationName:(NSString *)name;

@end