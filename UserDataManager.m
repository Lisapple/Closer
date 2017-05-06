//
//  UserDataManager.m
//  Closer
//
//  Created by Max on 01/05/2017.
//
//

#import "UserDataManager.h"
#import "UserDataEvent.h"

@implementation Countdown (date)

+ (NSDateFormatter *)keyValueStoreFormatter
{
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ"; // RFC 3339
	return formatter;
}

- (nullable NSString *)endDateString
{
	return (self.endDate) ? [self.class.keyValueStoreFormatter stringFromDate:self.endDate] : nil;
}

@end

static UserDataManager * __defaultManager = nil;

NSString * const KeyValueStoreCountdownsKey = @"countdowns"; // Value is of `KVSCountdowns` type

/// A dictionary with countdown or timer informations:
///   common keys: `@{ "id": identifier, "name": name, "message": message, "theme": theme as int
///                    "sound": songID, "notif": notificationCenter as bool }`
///   countdown: `@{ "type": 0, "endDate": "2017-30-04T21:32:43+02:00" }`
///   timer:	 `@{ "type": 1, "prompt": promptState as int, "durations": [ { "name": name or "", "seconds": duration } ] }`
typedef NSDictionary <NSString *, id> KVSCountdown;

/// An array of dictionary with all countdowns
typedef NSArray <KVSCountdown *> KVSCountdowns;

NSString * const UserDataEventsKey = @"userDataEvents";

@interface UserDataManager ()

/// Non-shared local user defaults; contains notes (`note_[infinitif]`), last selected playlist (`UserDefaultsLastUsedPlaylistKey`) and verb displayed count `UserDefaultsVerbPopularitiesKey`
@property (nonatomic, strong) NSUserDefaults * userDefaults;

/// iCloud store
@property (nonatomic, strong) NSUbiquitousKeyValueStore * keyValueStore;

/// Remove old events (more than 2 weeks) that should not be applied on iCloud synchronisation merge.
/// This also clean up saved events if iCloud sync is disabled to avoid growing user default storage.
- (void)removeStaleEvents;

@end

@implementation UserDataManager

+ (instancetype)defaultManager
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__defaultManager = [[UserDataManager alloc] init];
	});
	return __defaultManager;
}

- (instancetype)init
{
	if ((self = [super init])) {
		_userDefaults = [NSUserDefaults standardUserDefaults]; // Synchronization not needed to get it up to date
		_keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateExternalStore:)
													 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
												   object:nil];
		[self startObservingEventNotifications];
		
		[_keyValueStore synchronize];
	}
	return self;
}

- (void)removeStaleEvents
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray <UserDataEvent *> * events = [NSMutableArray arrayWithCapacity:10];
	for (NSData * eventData in [userDefaults arrayForKey:UserDataEventsKey]) {
		UserDataEvent * const event = [NSKeyedUnarchiver unarchiveObjectWithData:eventData];
		if (event) [events addObject:event];
	}
	
	NSDate * const date = [NSDate dateWithTimeIntervalSinceNow:-2 * 7 * 24 * 60 * 60]; // 2 weeks
	[events filterUsingPredicate:[NSPredicate predicateWithFormat:@"%K > %@", NSStringFromSelector(@selector(timestamp)), date]];
	
	NSMutableArray <NSData *> * eventDatas = ([userDefaults arrayForKey:UserDataEventsKey] ?: @[]).mutableCopy;
	for (UserDataEvent * event in events)
		[eventDatas addObject:[NSKeyedArchiver archivedDataWithRootObject:event]];
	
	[userDefaults setObject:eventDatas forKey:UserDataEventsKey]; // ???: Should be saved as dict with timestamp as key (more efficient)?
}

- (NSArray <NSString *> *)eventNotificationNames
{
	return @[ CountdownDidCreateNotification, CountdownDidMoveNotification, CountdownDidDeleteNotification ];
}

- (void)startObservingEventNotifications
{
	for (NSString * name in self.eventNotificationNames)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveEvent:) name:name object:nil];
}

- (void)stopObservingEventNotifications
{
	for (NSString * name in self.eventNotificationNames)
		[[NSNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
}

- (void)saveEvent:(NSNotification *)notification
{
	UserDataEvent* (^createEventFromNotification)(NSNotification *) = ^UserDataEvent*(NSNotification * notification) {
		
		if /**/ ([notification.name isEqualToString:CountdownDidCreateNotification]) {
			UDCountdownInsertEvent * event = [[UDCountdownInsertEvent alloc] init];
			assert([notification.object isKindOfClass:Countdown.class]);
			Countdown * countdown = notification.object;
			event.countdownIdentifier = countdown.identifier;
			event.index = [Countdown indexOfCountdown:countdown];
			event.notificationCenter = countdown.notificationCenter;
			return event;
		}
		else if ([notification.name isEqualToString:CountdownDidMoveNotification]) {
			UDCountdownMoveEvent * event = [[UDCountdownMoveEvent alloc] init];
			assert([notification.object isKindOfClass:Countdown.class]);
			Countdown * countdown = notification.object;
			event.countdownIdentifier = countdown.identifier;
			event.toIndex = [Countdown indexOfCountdown:countdown];
			event.fromIndex = [notification.userInfo[@"oldIndex"] integerValue];
			event.notificationCenter = countdown.notificationCenter;
			return event;
		}
		else if ([notification.name isEqualToString:CountdownDidDeleteNotification]) {
			UDCountdownDeleteEvent * event = [[UDCountdownDeleteEvent alloc] init];
			assert([notification.object isKindOfClass:NSString.class]);
			event.countdownIdentifier = (NSString *)notification.object;
			return event;
		}
		assert(false);
	};
	UserDataEvent * event = createEventFromNotification(notification);
	NSDebugLog(@"Saving user data event: %@", event);
	
	// Save event to user defaults
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray <NSData *> * eventDatas = ([userDefaults arrayForKey:UserDataEventsKey] ?: @[]).mutableCopy;
	[eventDatas addObject:[NSKeyedArchiver archivedDataWithRootObject:event]];
	[userDefaults setObject:eventDatas forKey:UserDataEventsKey];
}

- (void)updateExternalStore:(NSNotification *)notification
{
	NSNumber * const changeReason = notification.userInfo[NSUbiquitousKeyValueStoreChangeReasonKey];
	if (!changeReason)
		return ;
	
	BOOL hasChanges = ((changeReason.integerValue == NSUbiquitousKeyValueStoreServerChange) ||
					   (changeReason.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange));
	if (hasChanges) {
		NSArray * const changedKeys = notification.userInfo[NSUbiquitousKeyValueStoreChangedKeysKey];
		for (NSString * key in changedKeys) {
			if ([key isEqualToString:KeyValueStoreCountdownsKey]) {
				
				KVSCountdowns * countdowns = (KVSCountdowns *)[_keyValueStore arrayForKey:KeyValueStoreCountdownsKey];
				for (KVSCountdown * countdownDict in countdowns) {
					
					const CountdownType type = [countdownDict[@"type"] unsignedIntegerValue];
					NSString * const name = countdownDict[@"name"];
					NSDate * const endDate = [Countdown.keyValueStoreFormatter dateFromString:countdownDict[@"endDate"]];
					
					NSArray <NSDictionary *> * durationsDict = countdownDict[@"durations"];
					
					NSString * const identifier = countdownDict[@"id"];
					Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
					if (!countdown) { // Find a similar existing countdown (same name and same endDate or durations (ignoring names))
						
						BOOL (^predicate)(Countdown * _Nullable countdown, NSDictionary * bindings) = ^BOOL(Countdown * _Nullable countdown, NSDictionary * bindings) {
							BOOL sameTypeAndName = (countdown.type == type && [countdown.name isEqualToString:name]);
							if (countdown.type == CountdownTypeCountdown) {
								return (sameTypeAndName && [countdown.endDate isEqualToDate:endDate]);
							} else {
								NSMutableArray <NSNumber *> * durations = [NSMutableArray array];
								for (NSDictionary * durationDict in durationsDict)
									[durations addObject:@([durationDict[@"seconds"] integerValue])];
								
								BOOL sameDurations = [countdown.durations isEqualToArray:durations];
								return (sameTypeAndName && sameDurations);
							}
						};
						countdown = [Countdown.allCountdowns filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:predicate]].firstObject;
					}
					
					if (!countdown) { // No found, create a new one
						countdown = [[Countdown alloc] initWithIdentifier:identifier];
						countdown.name = name;
						if (type == CountdownTypeCountdown) {
							countdown.endDate = endDate;
						} else {
							for (NSDictionary * durationDict in durationsDict)
								[countdown addDuration:@([durationDict[@"seconds"] integerValue])
											  withName:durationDict[@"name"]];
						}
						[Countdown addCountdown:countdown];
					}
					countdown.style = [countdownDict[@"style"] unsignedIntegerValue];
					countdown.songID = countdownDict[@"songID"];
					countdown.notificationCenter = [countdownDict[@"notif"] boolValue];
					countdown.promptState = [countdownDict[@"prompt"] unsignedIntegerValue];
					
					if (countdown.message.length < [countdownDict[@"message"] length]) // Keep longest message
						countdown.message = countdownDict[@"message"];
					
					if (type == CountdownTypeTimer && countdown.durations.count == durationsDict.count) {
						NSInteger index = 0; for (NSDictionary * durationDict in durationsDict)
							[countdown setDurationName:durationDict[@"name"]
											   atIndex:index++];
					}
				}
			}
		}
		
		// Re-apply events
		[self stopObservingEventNotifications];
		
		[self removeStaleEvents];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray <UserDataEvent *> * events = [NSMutableArray arrayWithCapacity:10];
		for (NSData * eventData in [userDefaults arrayForKey:UserDataEventsKey]) {
			UserDataEvent * const event = [NSKeyedUnarchiver unarchiveObjectWithData:eventData];
			if (event) [events addObject:event];
		}
		[events sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(timestamp))
																	  ascending:YES] ]];
		
		for (UserDataEvent * anEvent in events) {
			if /**/ ([anEvent isKindOfClass:UDCountdownInsertEvent.class]) {
				UDCountdownInsertEvent * event = (UDCountdownInsertEvent *)anEvent;
				if (event.countdown) {
					const NSInteger index = [Countdown indexOfCountdown:event.countdown];
					[Countdown moveCountdownAtIndex:index toIndex:event.index];
				}
			}
			else if ([anEvent isKindOfClass:UDCountdownMoveEvent.class]) {
				UDCountdownMoveEvent * event = (UDCountdownMoveEvent *)anEvent;
				if (event.countdown) {
					const NSInteger index = [Countdown indexOfCountdown:event.countdown];
					[Countdown moveCountdownAtIndex:index toIndex:event.toIndex];
				}
			}
			else if ([anEvent isKindOfClass:UDCountdownDeleteEvent.class]) {
				UDCountdownDeleteEvent * event = (UDCountdownDeleteEvent *)anEvent;
				if (event.countdown)
					[Countdown removeCountdown:event.countdown];
			}
		}
		[userDefaults removeObjectForKey:UserDataEventsKey];
		
		[Countdown synchronize];
		
		[self startObservingEventNotifications];
	}
}

- (BOOL)synchronize
{
	[self removeStaleEvents];
	
	NSArray <Countdown *> * allCountdowns = [Countdown allCountdowns];
	NSMutableArray <NSDictionary <NSString *, NSObject *> *> * countdowns = [NSMutableArray arrayWithCapacity:allCountdowns.count];
	for (Countdown * countdown in allCountdowns) {
		NSMutableDictionary * countdownDict = @{ @"id": countdown.identifier,
												 @"type": @(countdown.type == CountdownTypeTimer),
												 @"name": countdown.name ?: @"---",
												 @"theme": @(countdown.style),
												 @"notif": @(countdown.notificationCenter) }.mutableCopy;
		if (countdown.message)
			countdownDict[@"message"] = countdown.message;
		
		if (countdown.songID)
			countdownDict[@"sound"] = countdown.songID;
		
		if (countdown.type == CountdownTypeTimer) {
			countdownDict[@"endDate"] = countdown.endDateString;
		} else {
			NSMutableArray <NSDictionary *> * durations = [NSMutableArray arrayWithCapacity:countdown.durations.count];
			NSInteger index = 0;
			for (NSNumber * duration in countdown.durations) {
				[durations addObject:@{ @"name": countdown.names[index] ?: @"",
										@"seconds": @(duration.integerValue) }];
				++index;
			}
			countdownDict[@"durations"] = durations;
			countdownDict[@"prompt"] = @(countdown.promptState);
		}
		[countdowns addObject:countdownDict];
	}
	[_keyValueStore setArray:countdowns forKey:KeyValueStoreCountdownsKey];
	
	return [_keyValueStore synchronize];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
