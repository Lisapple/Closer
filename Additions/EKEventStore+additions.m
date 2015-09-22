//
//  EKEventStore+additions.m
//  Closer
//
//  Created by Maxime Leroy on 2/2/13.
//
//

#import "EKEventStore+additions.h"

@implementation EKEventStore (additions)

- (NSUInteger)numberOfEventsMatchingPredicate:(NSPredicate *)predicate
{
	__block NSUInteger count = 0;
	[self enumerateEventsMatchingPredicate:predicate
								usingBlock:^(EKEvent *event, BOOL *stop) {
									count++;
								}];
	return count;
}

- (NSUInteger)numberOfEventsWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate calendar:(EKCalendar *)calendar
{
	NSPredicate * predicate = [self predicateForEventsWithStartDate:startDate
															endDate:endDate
														  calendars:@[calendar]];
	__block NSUInteger count = 0;
	[self enumerateEventsMatchingPredicate:predicate
								usingBlock:^(EKEvent *event, BOOL *stop) {
									count++;
								}];
	return count;
}

- (NSArray <EKEvent *> *)eventsWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate calendar:(EKCalendar *)calendar
{
	NSPredicate * predicate = [self predicateForEventsWithStartDate:startDate
															endDate:endDate// Fetch all future events that the eventStore could store
														  calendars:@[calendar]];
	NSArray * events = [self eventsMatchingPredicate:predicate];
	if (!events) {// If "events" is nil, return an empty array
		return @[];
	} else {// Else, return the sorted array
		return [events sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
	}
}

- (NSUInteger)numberOfFutureEventsFromCalendar:(EKCalendar *)calendar includingRecurrent:(BOOL)includeRecurrent
{
	NSPredicate * predicate = [self predicateForEventsWithStartDate:[NSDate date]
															endDate:[NSDate distantFuture]// Fetch all future events that the eventStore could store
														  calendars:@[calendar]];
	
	__block BOOL hasRecurrenceRulesPropertyExists = ([EKEvent instancesRespondToSelector:@selector(hasRecurrenceRules)]);
	
	__block NSUInteger count = 0;
	[self enumerateEventsMatchingPredicate:predicate
								usingBlock:^(EKEvent *event, BOOL *stop) {
									BOOL isRecurrent = (hasRecurrenceRulesPropertyExists)? (event.hasRecurrenceRules) : (/*[event recurrenceRule] != nil*/ NO);
									if (includeRecurrent
										|| (!isRecurrent || event.isDetached)) // If the event is not a recurrent item or is detached (different from others reccurent items)
										count++;
								}];
	return count;
}

- (NSArray <EKEvent *> *)futureEventsFromCalendar:(EKCalendar *)calendar includingRecurrent:(BOOL)includeRecurrent
{
	NSPredicate * predicate = [self predicateForEventsWithStartDate:[NSDate date]
															endDate:[NSDate distantFuture]// Fetch all future events that the eventStore could store
														  calendars:@[calendar]];
	
	BOOL hasRecurrenceRulesPropertyExists = ([EKEvent instancesRespondToSelector:@selector(hasRecurrenceRules)]);
	
	__block NSMutableArray * events = [[NSMutableArray alloc] initWithCapacity:10];
	[self enumerateEventsMatchingPredicate:predicate
								usingBlock:^(EKEvent *event, BOOL *stop) {
									BOOL isRecurrent = (hasRecurrenceRulesPropertyExists)? (event.hasRecurrenceRules) : (/*event.recurrenceRule != nil*/ NO);
									if (includeRecurrent
										|| (!isRecurrent || event.isDetached)) { // If the event is not a recurrent item or is detached (different from others reccurent items)
										[events addObject:event];
									}
								}];
	return (NSArray *)events;
}

@end
