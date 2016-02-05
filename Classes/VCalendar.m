//
//  VCalendar.m
//  Closer
//
//  Created by Max on 08/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VCalendar.h"

#import "NSDate+addition.h"

@implementation VEvent

+ (VEvent *)eventFromCountdown:(Countdown *)countdown
{
	if (countdown.endDate) {
		VEvent * event = [[VEvent alloc] initWithUUID:[NSUUID UUID].UUIDString];
		event.startDate = countdown.endDate;
		event.duration = kDefaultEventDuration;
		event.summary = countdown.name;
		event.message = countdown.message;
		
		return event;
	}
	return nil;
}

- (instancetype)init
{
	if ((self = [self initWithUUID:nil])) {}
	return self;
}

- (instancetype)initWithUUID:(NSString *)seed
{
	if ((self = [super init])) {
		_UUID = [seed copy];
	}
	return self;
}

@end

@interface VCalendar ()

@property (nonatomic, strong) NSString * version;
@property (nonatomic, strong) NSMutableArray <VEvent *> * events;

@end

@implementation VCalendar

- (instancetype)init
{
	if ((self = [self initWithVersion:@"2.0"])) {}
	return self;
}

- (instancetype)initWithVersion:(NSString *)versionString
{
    if ((self = [super init])) {
		_version = versionString;
		_events = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return self;
}

- (void)addEvent:(VEvent *)event
{
	if (event && ![_events containsObject:event])
		[_events addObject:event];
}

- (void)removeEvent:(VEvent *)event
{
	[_events removeObject:event];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag
{
	NSMutableString * string = [NSMutableString stringWithCapacity:200];
	
	[string appendString:@"BEGIN:VCALENDAR\n"];
	[string appendFormat:@"VERSION:%@\n", _version];
	
	NSString * currentLanguage = (NSString *)[NSBundle mainBundle].preferredLocalizations[0];
	[string appendFormat:@"PRODID:-//Lis@cintosh//NONSGML Closer&Closer//%@\n", currentLanguage.uppercaseString];
	
	for (VEvent * event in _events) {
		
		/* Example of ICAL event format:
		 BEGIN:VEVENT
		 UID:UUID
		 DTSTAMP:19970714T170000Z
		 DTSTART:19970714T170000Z
		 DTEND:19970715T035959Z
		 SUMMARY:Bastille Day Party
		 DESCRIPTION:This is an event reminder
		 END:VEVENT
		 */
		
		[string appendString:@"BEGIN:VEVENT\n"];
		{
			if (event.UUID) [string appendFormat:@"UID:%@\n", event.UUID];
			[string appendFormat:@"DTSTAMP:%@\n", event.startDate.rfc5545Format];
			[string appendFormat:@"DTSTART:%@\n", event.startDate.rfc5545Format];
			
			NSDate * endDate = [event.startDate dateByAddingTimeInterval:event.duration];
			[string appendFormat:@"DTEND:%@\n", endDate.rfc5545Format];
			
			NSString * formattedSummary = [event.summary stringByReplacingOccurrencesOfString:@"," withString:@"\\,"];// Remove occurrences of "," by "\,"
			[string appendFormat:@"SUMMARY:%@\n", formattedSummary];
			
			/* Format the description (see http://tools.ietf.org/html/rfc5545#section-3.8.1.5) */
			NSString * formattedDescription = [event.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];// Remove occurrences of CRL by "\n"
			formattedDescription = [formattedDescription stringByReplacingOccurrencesOfString:@"," withString:@"\\,"];// Remove occurrences of "," by "\,"
			[string appendFormat:@"DESCRIPTION:%@\n", formattedDescription];
		}
		[string appendString:@"END:VEVENT\n"];
	}
	[string appendString:@"END:VCALENDAR"];
	
	NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [data writeToFile:path atomically:flag];
}

@end