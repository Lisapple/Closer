//
//  EKEventStore+additions.h
//  Closer
//
//  Created by Maxime Leroy on 2/2/13.
//
//

#import <EventKit/EventKit.h>

@interface EKEventStore (additions)

- (NSUInteger)numberOfEventsMatchingPredicate:(NSPredicate *)predicate;

- (NSUInteger)numberOfEventsWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate calendar:(EKCalendar *)calendar;
- (NSArray <EKEvent *> *)eventsWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate calendar:(EKCalendar *)calendar;

- (NSUInteger)numberOfFutureEventsFromCalendar:(EKCalendar *)calendar includingRecurrent:(BOOL)includeRecurrent;
- (NSArray  <EKEvent *> *)futureEventsFromCalendar:(EKCalendar *)calendar includingRecurrent:(BOOL)includeRecurrent;

@end
