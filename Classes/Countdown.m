//
//  Countdown.m
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "Countdown.h"

#import "Constants.h"

#import "NSBundle+addition.h"
#import "NSArray+addition.h"

NSString * const CountdownDidSynchronizeNotification = @"CountdownDidSynchronizeNotification";
NSString * const CountdownDidUpdateNotification = @"CountdownDidUpdateNotification";

NSString * CountdownStyleDescription(CountdownStyle style) {
	switch (style) {
		// Regular styles
		case CountdownStyleNight:
			return NSLocalizedString(@"PAGE_STYLE_NIGHT", nil);
		case CountdownStyleDay:
			return NSLocalizedString(@"PAGE_STYLE_DAY", nil);
		case CountdownStyleDawn:
			return NSLocalizedString(@"PAGE_STYLE_DAWN", nil);
		case CountdownStyleOasis:
			return NSLocalizedString(@"PAGE_STYLE_OASIS", nil);
		case CountdownStyleSpring:
			return NSLocalizedString(@"PAGE_STYLE_SPRING", nil);
	}
	return nil;
}

BOOL CountdownStyleHasDarkContent(CountdownStyle style) {
	return (style == CountdownStyleDay || style == CountdownStyleSpring);
}

@interface Countdown ()

@property (nonatomic, strong) NSMutableArray <NSNumber *> * durations;
@property (nonatomic, strong) NSMutableArray <NSString *> * names;
@property (nonatomic, assign) NSTimeInterval remaining;
@property (nonatomic, assign) BOOL active;

@end

@implementation Countdown

static NSString * _countdownsListPath = nil;
static NSMutableArray * _propertyList = nil;
static NSMutableArray * _countdowns = nil;

#pragma mark - Class methods

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		// Since Closer uses UIFileSharingEnabled, Document folder is reserved for sharing only, move Countdowns.plist (renamed from Countdown.plist) file to ~/Library/Preferences/
		NSString * preferencesFolderPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
		_countdownsListPath = [[NSString alloc] initWithFormat:@"%@/Preferences/Countdowns.plist", preferencesFolderPath];
		
		NSError * error = nil;
		NSData * data = [NSData dataWithContentsOfFile:_countdownsListPath];
		if (!data) { // If no Countdowns.plist have been found, look up at ~/Documents/Countdown.plist ...
			
			NSString * documentFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
			NSString * oldCountdownPath = [NSString stringWithFormat:@"%@/Countdown.plist", documentFolderPath];
			data = [NSData dataWithContentsOfFile:oldCountdownPath];
			
			if (!data) { // ...And if no file exist at ~/Documents/Countdown.plist, fetch default plist file from Closer bundle
				NSString * path = [[NSBundle mainBundle] pathForResource:@"Countdown" ofType:@"plist"];
				data = [NSData dataWithContentsOfFile:path];
			}
			
			// Force to move the current (or default) countdown list file to ~/Library/Preferences/
			BOOL success = [data writeToFile:_countdownsListPath options:NSDataWritingAtomic error:&error];
			
			if (!success) {
				NSLog(@"error on writing file to : %@ => [%@]", _countdownsListPath, error.localizedDescription);
			}
			
			// And then, remove the file at ~/Documents/Countdown.plist to not show it on iTunes Sharing */
			if ([[NSFileManager defaultManager] fileExistsAtPath:oldCountdownPath]) {
				error = nil;
				success = [[NSFileManager defaultManager] removeItemAtPath:oldCountdownPath error:&error];
				
				if (!success) {
					NSLog(@"error when removing file to : %@ => [%@]", _countdownsListPath, error.localizedDescription);
				}
			}
		}
		
		NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
		_propertyList = [NSPropertyListSerialization propertyListWithData:data
																  options:NSPropertyListMutableContainersAndLeaves
																   format:&format
																	error:&error];
		if (![_propertyList isKindOfClass:[NSMutableArray class]])
			[NSException raise:@"CountdownException" format:@"Countdown.plist should be an mutable array based format."];
		
		_countdowns = [[NSMutableArray alloc] initWithCapacity:_propertyList.count];
		for (NSDictionary * dictionary in _propertyList) {
			Countdown * countdown = [[Countdown alloc] initWithDictionary:dictionary];
			[countdown activate];
			[_countdowns addObject:countdown];
		}
		[_countdowns sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"notificationCenter" ascending:NO] ]];
		
		[NSNotificationCenter.defaultCenter addObserverForName:CountdownDidUpdateNotification
														object:nil queue:NSOperationQueue.currentQueue
													usingBlock:^(NSNotification *note) {
														[self.class updateUserDefaults];
													}];
		[NSNotificationCenter.defaultCenter addObserverForName:CountdownDidSynchronizeNotification
														object:nil queue:NSOperationQueue.currentQueue
													usingBlock:^(NSNotification *note) {
														[self updateUserDefaults];
														
														NSPredicate * predicate = [NSPredicate predicateWithFormat:@"notificationCenter == YES"];
														NSArray * includedCountdowns = [_countdowns filteredArrayUsingPredicate:predicate];
														[[NCWidgetController widgetController] setHasContent:(includedCountdowns.count > 0)
																			   forWidgetWithBundleIdentifier:@"com.lisacintosh.closer.Widget"];
													}];
		if (_countdowns.count > 0)
			[NSNotificationCenter.defaultCenter postNotificationName:CountdownDidSynchronizeNotification object:nil];
	}
}

+ (void)updateUserDefaults
{
	if ([NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)]) {
		static NSUserDefaults * sharedDefaults = nil;
		if (!sharedDefaults)
			sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.closer"];
		
		NSMutableArray * includedCountdowns = [_countdowns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"notificationCenter == YES"]].mutableCopy;
		[includedCountdowns sortUsingComparator:^NSComparisonResult(Countdown * countdown1, Countdown * countdown2) {
			return OrderComparisonResult([_countdowns indexOfObject:countdown1], [_countdowns indexOfObject:countdown2]); }];
		
		[sharedDefaults setObject:[includedCountdowns valueForKeyPath:@"countdownToDictionary"]
						   forKey:@"countdowns"];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * identifier = [userDefaults stringForKey:kLastSelectedCountdownIdentifierKey];
		
		Countdown * countdown = [Countdown countdownWithIdentifier:identifier] ?: _countdowns.firstObject;
		[sharedDefaults setObject:countdown.identifier forKey:@"selectedIdentifier"];
		[sharedDefaults synchronize];
		
		if (NSClassFromString(@"WCSession") && [WCSession isSupported]
			&& [WCSession defaultSession].isWatchAppInstalled && countdown.identifier) {
			NSDictionary * context = @{ @"countdowns" : [includedCountdowns valueForKeyPath:@"JSONDictionary"], @"selectedIdentifier": countdown.identifier };
			NSError * error = nil;
			BOOL success = [[WCSession defaultSession] updateApplicationContext:context error:&error];
			if (!success) {
				NSLog(@"error: %@", error.localizedDescription);
			}
			[[WCSession defaultSession] sendMessage:@{ @"update" : @YES }
									   replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
										   dispatch_sync(dispatch_get_main_queue(), ^{
#if TARGET_IPHONE_SIMULATOR
											   UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reply", nil)
																											   message:replyMessage.description
																										preferredStyle:UIAlertControllerStyleAlert];
											   [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:nil]];
											   [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:NULL];
#endif
										   });
									   }
									   errorHandler:^(NSError * _Nonnull error) {
										   dispatch_sync(dispatch_get_main_queue(), ^{
#if TARGET_IPHONE_SIMULATOR
											   UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reply error", nil)
																											   message:error.localizedDescription
																										preferredStyle:UIAlertControllerStyleAlert];
											   [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:nil]];
											   [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:NULL];
#endif
										   });
									   }];
		}
	}
}

+ (void)synchronize
{
	[self synchronizeWithCompletion:^(BOOL success, NSError *error) {
		if (error) {
			UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR_ALERT_TITLE", nil)
																			message:error.localizedDescription
																	 preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) { [alert dismissViewControllerAnimated:YES completion:nil]; }]];
			UIViewController * rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
			[rootViewController presentViewController:alert animated:YES completion:nil];
		}
	}];
}

+ (void)synchronize_async
{
	[self synchronizeWithCompletion:NULL];
}

+ (void)synchronizeWithCompletion:(void (^)(BOOL success, NSError * error))completionHandler
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		@synchronized(_countdowns) {
			[_propertyList removeAllObjects];
			[_countdowns enumerateObjectsUsingBlock:^(Countdown *countdown, NSUInteger idx, BOOL *stop) {
				[_propertyList addObject:[countdown countdownToDictionary]]; }];
		}
		
		NSError * error = nil;
		const NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
		NSData * data = [NSPropertyListSerialization dataWithPropertyList:_propertyList format:format options:0 error:&error];
		if (!data) {
			NSLog(@"Error when serialize property list : %@", error.localizedDescription);
			
			if (completionHandler) {
				NSError * error = [NSError errorWithDomain:@"CountdownErrorDomain"
													  code:1
												  userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"READING_ERROR_ALERT_MESSAGE", nil) }];
				completionHandler(NO, error);
			}
			return;
		}
		
		error = nil;
		BOOL succeed = [data writeToFile:_countdownsListPath options:NSDataWritingAtomic error:&error]; // Write data atomically
		if (!succeed) {
			NSLog(@"error on writing file to : %@ => [%@]", _countdownsListPath, error.localizedDescription);
			
			if (completionHandler) {
				NSError * error = [NSError errorWithDomain:@"CountdownErrorDomain" code:2
												  userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"WRITING_ERROR_ALERT_TITLE", nil) }];
				completionHandler(NO, error);
			}
			return;
		}
		
		NSNotification * notification = [NSNotification notificationWithName:CountdownDidSynchronizeNotification object:nil];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
		
		if (completionHandler)
			completionHandler(YES, nil);
	});
}

+ (NSInteger)numberOfCountdowns
{
	return _countdowns.count;
}

+ (NSArray *)allCountdowns
{
	return (NSArray *)_countdowns;
}

+ (Countdown *)countdownWithIdentifier:(NSString *)identifier
{
	for (Countdown * aCountdown in _countdowns) {
		if ([aCountdown.identifier isEqualToString:identifier])
			return aCountdown;
	}
	
	return nil;
}

+ (Countdown *)countdownAtIndex:(NSInteger)index
{
	return (Countdown *)_countdowns[index];
}

+ (NSInteger)indexOfCountdown:(Countdown *)countdown
{
	return [_countdowns indexOfObject:countdown];
}

+ (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index
{
	[Countdown tagInsert];
	
	[countdown activate];
	[_countdowns insertObject:countdown atIndex:index];
	
	[self synchronize];
}

+ (void)addCountdown:(Countdown *)countdown
{
	[Countdown tagInsert];
	
	[countdown activate];
	[_countdowns addObject:countdown];
	
	[self synchronize];
}

+ (void)addCountdowns:(NSArray *)countdowns
{
	for (Countdown * countdown in countdowns) {
		[Countdown tagInsert];
		[countdown activate];
	}
	
	[_countdowns addObjectsFromArray:countdowns];
	
	[self synchronize];
}

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		Countdown * countdown = _countdowns[fromIndex];
		[_countdowns removeObjectAtIndex:fromIndex];
		[_countdowns insertObject:countdown atIndex:toIndex];
		
		[self synchronize];
	}
}

+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2
{
	[_countdowns exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
	
	[self synchronize];
}

+ (void)removeCountdown:(Countdown *)countdown
{
	[Countdown tagDelete];
	
	[countdown remove];
	[countdown desactivate];
	[_countdowns removeObject:countdown];
	
	[self synchronize];
}

+ (void)removeCountdownAtIndex:(NSInteger)index
{
	Countdown * countdown = _countdowns[index];
	[self removeCountdown:countdown];
}

+ (NSArray <NSNumber *> *)styles
{
	return @[ @(CountdownStyleNight),
			  @(CountdownStyleDay),
			  @(CountdownStyleDawn),
			  @(CountdownStyleOasis),
			  @(CountdownStyleSpring) ];
}

+ (nonnull NSArray <NSString *> *)styleNames
{
	NSMutableArray <NSString *> * names = [NSMutableArray arrayWithCapacity:4];
	for (NSNumber * style in self.styles)
		[names addObject:CountdownStyleDescription((CountdownStyle)style.integerValue)];
	
	return names;
}

#pragma mark - Instance methods

- (NSDictionary *)countdownToDictionary
{
	NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithCapacity:_countdowns.count];
	dictionary[@"name"] = self.name;
	
	if (self.type == CountdownTypeCountdown) {
		if (self.endDate) dictionary[@"endDate"] = self.endDate;
		if (self.message) dictionary[@"message"] = self.message;
	} else {
		dictionary[@"durations"] = self.durations;
		dictionary[@"names"] = self.names;
		dictionary[@"durationIndex"] = @(self.durationIndex);
		
		if (self.endDate) dictionary[@"endDate"] = self.endDate;
		dictionary[@"prompt"] = @(self.promptState);
	}
	
	dictionary[@"songID"] = self.songID;
	dictionary[@"identifier"] = self.identifier;
	dictionary[@"style"] = @(self.style);
	dictionary[@"type"] = @(self.type);
	dictionary[@"notificationCenter"] = @(self.notificationCenter);
	
	return dictionary;
}

- (NSDictionary *)JSONDictionary
{
	NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithCapacity:_countdowns.count];
	dictionary[@"name"] = self.name;
	
	if (self.type == CountdownTypeCountdown) {
		if (self.message) dictionary[@"message"] = self.message;
	} else {
		dictionary[@"durations"] = self.durations;
		dictionary[@"names"] = self.names;
		dictionary[@"durationIndex"] = @(self.durationIndex);
	}
	
	if (self.endDate) {
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterMediumStyle;
		formatter.timeStyle = NSDateFormatterMediumStyle;
		dictionary[@"endDate"] = [formatter stringFromDate:self.endDate];
	}
	
	dictionary[@"identifier"] = self.identifier;
	dictionary[@"style"] = @(self.style);
	dictionary[@"type"] = @(self.type);
	return dictionary;
}

- (instancetype)init
{
	return [self initWithIdentifier:nil];
}

- (instancetype)initWithIdentifier:(NSString *)anIdentifier
{
	if ((self = [super init])) {
		_identifier = anIdentifier ?: [NSUUID UUID].UUIDString;
		
		/* Don't call self.xxx to not call updateLocalNotification many times */
		_name = NSLocalizedString(@"NO_TITLE_PLACEHOLDER", nil);
		_endDate = nil;
		_paused = YES;
		_message = @"";
		_songID = @"default";
		_style = 0;
		_type = CountdownTypeCountdown;
		_notificationCenter = YES;
		
		_durations = [[NSMutableArray alloc] initWithCapacity:5];
		_names = [[NSMutableArray alloc] initWithCapacity:5];
		
		[self update];
	}
	
	return self;
}

- (instancetype)initWithDictionary:(nonnull NSDictionary<NSString *, id> *)dictionary
{
	NSString * identifier = dictionary[@"identifier"];
	if ((self = [self initWithIdentifier:identifier])) {
		
		CountdownType type = [dictionary[@"type"] integerValue];
		if (type == CountdownTypeTimer) {
			_durations = dictionary[@"durations"];
			_names = dictionary[@"names"];
			if (_names.count < _durations.count) {
				for (NSUInteger _ = _names.count; _ <= _durations.count; ++_) { [_names addObject:@""]; }
			}
			NSAssert(_names.count == _durations.count, @"durations count must be equal to names count");
			
			_durationIndex = [dictionary[@"durationIndex"] integerValue];
			_promptState = [dictionary[@"prompt"] integerValue];
		} else { // Countdown
			_message = dictionary[@"message"];
		}
		
		_name = dictionary[@"name"];
		_endDate = dictionary[@"endDate"];
		_songID = dictionary[@"songID"];
		_style = [dictionary[@"style"] integerValue];
		_type = type;
		_notificationCenter = (dictionary[@"notificationCenter"]) ? [dictionary[@"notificationCenter"] boolValue] : YES;
		
		[self update];
	}
	return self;
}

- (BOOL)isActive
{
	return _active;
}

- (void)activate
{
	_active = YES;
}

- (void)desactivate
{
	_active = NO;
}

- (void)setName:(NSString *)aName
{
	if (aName && ![aName isEqualToString:_name]) {
		[Countdown tagChangeName];
		
		_name = aName;
		[self update];
	}
}

- (void)setMessage:(NSString *)aMessage
{
	if (aMessage && ![aMessage isEqualToString:_message]) {
		[Countdown tagChangeMessage];
		
		_message = aMessage;
		[self update];
	}
}

- (void)setEndDate:(NSDate *)aDate
{
	if (![_endDate isEqualToDate:aDate]) {
		if (aDate && _endDate)
			[Countdown tagEndDate:aDate];
		
		_endDate = aDate;
		_paused = (_endDate == nil);
		[self update];
	}
}

- (void)setSongID:(NSString *)aSongID
{
	if (aSongID && ![aSongID isEqualToString:_songID]) {
		_songID = aSongID;
		[self update];
	}
}

- (void)setStyle:(CountdownStyle)style
{
	if (_style != style) {
		[Countdown tagChangeTheme:style];
		
		_style = style;
		[self update];
	}
}

- (void)setType:(CountdownType)newType
{
	if (_type != newType) {
		[Countdown tagChangeType:newType];
		
		_type = newType;
		[self update];
	}
}

- (void)update
{
	[self updateLocalNotification];
}

- (void)remove
{
	[self removeLocalNotification];
}

#pragma mark - Timer

- (void)setDurationIndex:(NSInteger)index
{
	if (self.durations.count > 0)
		_durationIndex = index % self.durations.count;
}

- (NSNumber *)currentDuration
{
	/* Return the current duration (at index "duratonIndex" if not out of bounds, else return the first duration if exists, else return "nil" */
	return (_durationIndex <= ((NSInteger)_durations.count - 1)) ? _durations[_durationIndex] : _durations.firstObject;
}

- (NSArray *)durations
{
	return _durations;
}

- (NSString *)currentName
{
	return (_durationIndex <= ((NSInteger)_names.count - 1)) ? _names[_durationIndex] : _names.firstObject;
}

- (NSArray *)names
{
	return _names;
}

- (void)addDuration:(NSNumber *)duration withName:(NSString *)name
{
	[Countdown tagChangeDuration];
	
	[_durations addObject:duration];
	name = (name) ?: @"";
	[_names addObject:name];
}

- (void)addDurations:(NSArray <NSNumber *> *)durations withNames:(NSArray <NSString *> *)names
{
	[Countdown tagChangeDuration];
	
	NSAssert2((names && durations.count == names.count) || !names, @"The number of durations (%lu) must be the same as names (%lu), if names set",
			  (long)durations.count, (long)names.count);
	[_durations addObjectsFromArray:durations];
	if (names)
		[_names addObjectsFromArray:names];
	else {
		for (int _ = 0; _ < durations.count; ++_) [_names addObject:@""];
	}
}

- (void)setDuration:(NSNumber * _Nonnull)duration atIndex:(NSInteger)index
{
	_durations[index] = duration;
}

- (void)setDurationName:(NSString * _Nonnull)name atIndex:(NSInteger)index
{
	_names[index] = name;
}

- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		NSNumber * duration = _durations[fromIndex];
		[_durations removeObjectAtIndex:fromIndex];
		[_durations insertObject:duration atIndex:toIndex];
		
		NSString * name = _names[fromIndex];
		[_names removeObjectAtIndex:fromIndex];
		[_names insertObject:name atIndex:toIndex];
	}
}

- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2
{
	[_durations exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
	[_names exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)removeDurationAtIndex:(NSUInteger)index
{
	[Countdown tagChangeDuration];
	
	[_durations removeObjectAtIndex:index];
	if (index < _names.count) // If the case where the duration has no name (even an empty one), don't try to delete the name
		[_names removeObjectAtIndex:index];
}

- (void)resetDurationIndex
{
	_durationIndex = 0;
}

- (void)resume
{
	[self resumeWithOffset:0];
}

- (void)resumeWithOffset:(NSTimeInterval)offset
{
	if (_type == CountdownTypeTimer && _paused) {
		_endDate = [NSDate dateWithTimeIntervalSinceNow:_remaining + offset];
		_remaining = 0.;
		_paused = NO;
		[self updateLocalNotification];
	}
}

- (void)pause
{
	if (_type == CountdownTypeTimer && !_paused) {
		_remaining = ceil(_endDate.timeIntervalSinceNow);
		_endDate = nil;
		_paused = YES;
		[self updateLocalNotification];
	}
}

- (void)reset
{
	if (_type == CountdownTypeTimer && self.currentDuration) {
		_endDate = [NSDate dateWithTimeIntervalSinceNow:self.currentDuration.doubleValue];
		_paused = NO;
		[self updateLocalNotification];
	}
}

#pragma mark - Localized description

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index
{
	long seconds = _durations[index].longValue;
	long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
	long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
	long minutes = seconds / 60; seconds -= minutes * 60;
	
	NSInteger count = (days > 0) + (hours > 0) + (minutes > 0) + (seconds > 0);
	NSMutableArray * components = [[NSMutableArray alloc] initWithCapacity:4];
	if (count > 2) {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld %@ ", days, (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@ ", hours, (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@ ", minutes, NSLocalizedString(@"min", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld %@ ", seconds, NSLocalizedString(@"sec", nil)]];
	} else {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld %@", days, (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@", hours, (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@", minutes, (minutes > 1) ? NSLocalizedString(@"minutes", nil) : NSLocalizedString(@"minute", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld %@", seconds, (seconds > 1) ? NSLocalizedString(@"seconds", nil) : NSLocalizedString(@"second", nil)]];
	}
	return [components componentsJoinedByString:@", " withLastJoin:NSLocalizedString(@" and ", nil)]; // "12 minutes and 34 seconds", "12 days, 34 hours, 56 min and 12 sec"
}

- (NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index
{
	long seconds = _durations[index].longValue;
	long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
	long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
	long minutes = seconds / 60; seconds -= minutes * 60;
	
	NSInteger count = (days > 0) + (hours > 0) + (minutes > 0) + (seconds > 0);
	NSMutableArray * components = [[NSMutableArray alloc] initWithCapacity:count];
	if (count >= 3) {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld%@", days, NSLocalizedString(@"d", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld%@", hours, NSLocalizedString(@"h", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld%@", minutes, NSLocalizedString(@"m", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld%@", seconds, NSLocalizedString(@"s", nil)]];
	} else {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld %@", days, NSLocalizedString((days > 1) ? @"days" : @"day", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@", hours, NSLocalizedString((hours > 1) ? @"hours" : @"hour", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@", minutes, NSLocalizedString(@"min", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld %@", seconds, NSLocalizedString(@"sec", nil)]];
	}
	return [components componentsJoinedByString:@", " withLastJoin:NSLocalizedString(@" and ", nil)]; // "12 min and 34 sec", "12d, 34h, 56m and 12s"
}

#pragma mark - isEqual methods

- (BOOL)isEqual:(Countdown *)anotherCountdown
{
	return [super isEqual:anotherCountdown];
}

- (BOOL)isEqualTo:(Countdown *)anotherCountdown
{
	return [self isEqualToCountdown:anotherCountdown];
}

- (BOOL)isEqualToCountdown:(Countdown *)anotherCountdown
{
	return ([self.name isEqualToString:anotherCountdown.name]
			&& [self.endDate isEqualToDate:anotherCountdown.endDate]
			&& [self.message isEqualToString:anotherCountdown.message]
			&& [self.songID isEqualToString:anotherCountdown.songID]
			&& (self.style == anotherCountdown.style)
			&& (self.type == anotherCountdown.type));
}

#pragma mark - Description

- (NSString *)description
{
	NSMutableString * string = [[NSMutableString alloc] initWithCapacity:100];
	if (_type == CountdownTypeTimer)
		[string appendFormat:@"<Countdown (Timer): 0x%p; name = %@; durations = %@", self, _name, [_durations componentsJoinedByString:@","]];
	else
		[string appendFormat:@"<Countdown: 0x%p; name = %@; endDate = %@", self, _name, _endDate];
	[string appendFormat:@"; songID = %@", _songID];
	
	if (self.notificationCenter)
		[string appendString:@"; in notification center"];
	
	return [string stringByAppendingString:@">"];
}

#pragma mark - Memory management

- (void)dealloc
{
	// Remove the notification
	[self remove];
}

@end
