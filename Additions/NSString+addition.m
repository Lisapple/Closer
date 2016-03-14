//
//  NSString+addition.m
//  Closer
//
//  Created by Max on 21/01/16.
//
//

#import "NSString+addition.h"

@implementation NSString (addition)

- (BOOL)isMatchingWithPattern:(nonnull NSString *)pattern
{
	return [self isMatchingWithPattern:pattern firstMatch:nil];
}

- (BOOL)isMatchingWithPattern:(nonnull NSString *)pattern firstMatch:(NSString * _Nullable * _Nullable)pValue
{
	NSError * error = nil;
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern
																			options:NSRegularExpressionCaseInsensitive
																			  error:&error];
	if (error) {
		NSLog(@"Error: %@", error.localizedDescription);
	}
	
	NSRange range = NSMakeRange(0, self.length);
	if (pValue) {
		*pValue = [regex stringByReplacingMatchesInString:self options:0 range:range withTemplate:@"$1"];
	}
	return [regex matchesInString:self options:0 range:range].count;
}

@end
