//
//  UserDataEvent+addition.m
//  Closer
//
//  Created by Max on 18/06/2017.
//
//

#import "UserDataEvent+addition.h"

@implementation UserDataEvent (equal)

- (NSUInteger)hash
{
	return self.timestamp.hash;
}

- (BOOL)isEqual:(id)object
{
	UserDataEvent * const event = (UserDataEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [self.timestamp isEqualToDate:event.timestamp];
}

@end


@implementation UDCountdownEvent (equal)

- (NSUInteger)hash
{
	return super.hash ^ self.countdownIdentifier.hash;
}

- (BOOL)isEqual:(id)object
{
	UDCountdownEvent * const event = (UDCountdownEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.countdownIdentifier isEqualToString:event.countdownIdentifier];
}

@end


@implementation UDCountdownInsertEvent (equal)

- (NSUInteger)hash
{
	return super.hash ^ (self.notificationCenter * 0x1000) ^ (self.index * 0x2000);
}

- (BOOL)isEqual:(id)object
{
	UDCountdownInsertEvent * const event = (UDCountdownInsertEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& (self.notificationCenter == event.notificationCenter)
		&& (self.index == event.index);
}

@end


@implementation UDCountdownMoveEvent (equal)

- (NSUInteger)hash
{
	return super.hash ^ (self.notificationCenter * 0x1000)
		^ (self.fromIndex * 0x2000) ^ (self.toIndex * 0x3000);
}

- (BOOL)isEqual:(id)object
{
	UDCountdownMoveEvent * const event = (UDCountdownMoveEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& (self.notificationCenter == event.notificationCenter)
		&& (self.fromIndex == event.fromIndex)
		&& (self.toIndex == event.toIndex);
}

@end
