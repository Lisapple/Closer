//
//  NSArray+addition.m
//  Closer
//
//  Created by Maxime Leroy on 8/12/13.
//
//

#import "NSArray+addition.h"

@implementation NSArray (addition)

- (NSString *)componentsJoinedByString:(NSString *)join withLastJoin:(NSString *)endJoin
{
	NSInteger count = self.count;
	NSMutableString * string = [NSMutableString stringWithCapacity:(count * 10)];
	for (int i = 0; i < (count - 2); i++) {
		NSObject * component = self[i];
		[string appendFormat:@"%@%@", component.description, join];
	}
	if (count >= 2) {
		NSObject * component = self[count - 2];
		NSObject * lastComponent = self.lastObject;
		[string appendFormat:@"%@%@%@", component.description, endJoin, lastComponent.description];
		
	} else if (count == 1) // If we have only one item, return its description
		return [self.lastObject description];
	
	return (NSString *)string;
}

@end
