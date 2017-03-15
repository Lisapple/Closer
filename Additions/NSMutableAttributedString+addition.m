//
//  NSMutableAttributedString+addition.m
//  Closer
//
//  Created by Max on 16/01/2017.
//
//

#import "NSMutableAttributedString+addition.h"

@implementation NSMutableAttributedString (addition)

- (void)appendAttributes:(nullable NSDictionary<NSString *, id> *)attrs format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3)
{
	va_list args;
	va_start(args, format);
	NSString * string = [[NSString alloc] initWithFormat:format arguments:args];
	[self appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attrs]];
}

- (void)appendString:(NSString *)string attributes:(nullable NSDictionary<NSString *, id> *)attrs
{
	[self appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attrs]];
}

@end
