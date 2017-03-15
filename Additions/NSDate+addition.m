//
//  NSDate+addition.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSDate+addition.h"

@implementation NSDate(addition)

- (NSInteger)second
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"s";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSInteger)minute
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"m";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSString *)minuteString
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"mm";
	return [dateFormatter stringFromDate:self];
}

- (NSInteger)hour
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"H";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSInteger)day
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"dd";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSInteger)month
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"MM";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSInteger)year
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSInteger)daysFromNow
{
	NSCalendar * calendar = [NSCalendar currentCalendar];
	NSDateComponents * components = [calendar components:NSCalendarUnitDay fromDate:[NSDate date] toDate:self options:0];
	return components.day;
}

- (NSString *)naturalTimeString
{
	// Returns the more natural time format string. ex: 7h55
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale * locale = [NSLocale currentLocale];
	dateFormatter.locale = locale;
	dateFormatter.timeStyle = NSDateFormatterShortStyle;
	
	return [dateFormatter stringFromDate:self];
}

- (NSString *)naturalDateString
{
	// Returns the more natural date format string. e.g.: Mardi 7 Mars
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale * locale = [NSLocale currentLocale];
	dateFormatter.locale = locale;
	dateFormatter.dateStyle = NSDateFormatterShortStyle;
	dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMMyyyy" options:0 locale:nil];
	return [dateFormatter stringFromDate:self].capitalizedString;
}

- (NSString *)rfc5545Format
{
	// Returns a date at date-time format (yyyy MM dd 'T' HH mm ss 'Z')
	
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [NSLocale currentLocale];
	dateFormatter.dateFormat = @"yyyyMMdd'T'HHmmss'Z'";
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];// Set to GMT time zone
	
	return [dateFormatter stringFromDate:self];
}

- (NSString *)SQLDateTime
{
	// Returns a date at date-time format (YYYY-MM-dd HH:mm:ss)
	
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [NSLocale currentLocale];
	dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];// Set to GMT time zone
	
	return [dateFormatter stringFromDate:self];
}

- (NSString *)localizedDescription
{
	if (self.timeIntervalSinceNow < 0)
		return nil;
	
	/* Returns the smallest format. ex: 22/07/11, 16h09 */
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	
	NSLocale * locale = [NSLocale currentLocale];
	dateFormatter.locale = locale;
	dateFormatter.dateStyle = NSDateFormatterShortStyle;// e.g.: 22/07/11
	
	NSString * dateString = [dateFormatter stringFromDate:self];
	
	return [NSString stringWithFormat:@"%@, %@", dateString, [self naturalTimeString]];
}

@end
