//
//  UserDataEvent.m
//  Closer
//
//  Created by Max on 01/05/2017.
//
//

#import "UserDataEvent.h"

#define SelectorName(X) NSStringFromSelector(@selector(X))

@implementation UserDataEvent

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)init
{
	if ((self = [super init])) {
		_timestamp = [NSDate date];
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init])) {
		_timestamp = [aDecoder decodeObjectOfClass:NSDate.class
											forKey:SelectorName(timestamp)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_timestamp forKey:SelectorName(timestamp)];
}

@end


@implementation UDCountdownEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_countdownIdentifier = [aDecoder decodeObjectOfClass:NSString.class
											   forKey:SelectorName(countdownIdentifier)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_countdownIdentifier
				  forKey:SelectorName(countdownIdentifier)];
}

- (Countdown *)countdown
{
	return [Countdown countdownWithIdentifier:_countdownIdentifier];
}

@end


@implementation UDCountdownInsertEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_index = [aDecoder decodeIntegerForKey:SelectorName(index)];
		_notificationCenter = [aDecoder decodeBoolForKey:SelectorName(notificationCenter)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeInteger:_index forKey:SelectorName(index)];
	[aCoder encodeBool:_notificationCenter forKey:SelectorName(notificationCenter)];
}

@end


@implementation UDCountdownMoveEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_toIndex = [aDecoder decodeIntegerForKey:SelectorName(toIndex)];
		_fromIndex = [aDecoder decodeIntegerForKey:SelectorName(fromIndex)];
		_notificationCenter = [aDecoder decodeBoolForKey:SelectorName(notificationCenter)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeInteger:_toIndex forKey:SelectorName(toIndex)];
	[aCoder encodeInteger:_fromIndex forKey:SelectorName(fromIndex)];
	[aCoder encodeBool:_notificationCenter forKey:SelectorName(notificationCenter)];
}

@end


@implementation UDCountdownDeleteEvent

@end
