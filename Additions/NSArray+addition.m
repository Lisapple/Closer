//
//  NSArray+addition.m
//  Closer
//
//  Created by Maxime Leroy on 8/12/13.
//
//

#import "NSArray+addition.h"

@implementation NSArray (addition)

- (NSString *)componentsJoinedByString:(NSString *)separator andLastString:(NSString *)endSeparator
{
	NSInteger count = self.count;
	NSMutableString * string = [NSMutableString stringWithCapacity:(count * 10)];
	for (int i = 0; i < (count - 2); i++) {
		NSObject * component = self[i];
		[string appendFormat:@"%@%@", component.description, separator];
	}
	if (count >= 2) {
		NSObject * component = self[count - 2];
		NSObject * lastComponent = self.lastObject;
		[string appendFormat:@"%@%@%@", component.description, endSeparator, lastComponent.description];
	} else if (count == 1) { // If we have only one item, return its description
		return [self.lastObject description];
	}
	
	return (NSString *)string;
}

@end
