//
//  UserDataEvent.h
//  Closer
//
//  Created by Max on 01/05/2017.
//
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface UserDataEvent : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly) NSDate * timestamp;

@end


@interface /* abstract */ UDCountdownEvent : UserDataEvent

@property (nonatomic, strong) NSString * countdownIdentifier;
@property (nonatomic, readonly, nullable) Countdown * countdown;

@end

@interface UDCountdownInsertEvent : UDCountdownEvent

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL notificationCenter;

@end

@interface UDCountdownMoveEvent : UDCountdownEvent

@property (nonatomic, assign) NSInteger fromIndex, toIndex;
@property (nonatomic, assign) BOOL notificationCenter;

@end

@interface UDCountdownDeleteEvent : UDCountdownEvent

@end

NS_ASSUME_NONNULL_END
