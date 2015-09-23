//
//  Countdown.m
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "Countdown.h"
#import "Countdown+addition.h"

#import "NSBundle+addition.h"
#import "NSArray+addition.h"

NSString * const CountdownDidSynchronizeNotification = @"CountdownDidSynchronizeNotification";
NSString * const CountdownDidUpdateNotification = @"CountdownDidUpdateNotification";

@interface Countdown ()

@property (nonatomic, strong) NSMutableArray <NSNumber *> * durations;
@property (nonatomic, assign) NSTimeInterval remaining;
@property (nonatomic, assign) BOOL active;

@end

@implementation Countdown

static NSString * _countdownsListPath = nil;
static NSMutableArray * _propertyList = nil;
static NSMutableArray * _countdowns = nil;

#pragma mark - Countdown's Class Methods

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		/* Since Closer uses UIFileSharingEnabled, Document folder is reserved for sharing only, move Countdowns.plist (renamed from Countdown.plist) file to ~/Library/Preferences/ */
		NSString * preferencesFolderPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
		_countdownsListPath = [[NSString alloc] initWithFormat:@"%@/Preferences/Countdowns.plist", preferencesFolderPath];
		
		NSError * error = nil;
		NSData * data = [NSData dataWithContentsOfFile:_countdownsListPath];
		if (!data) {// If no Countdowns.plist have been found, look up at ~/Documents/Countdown.plist ...
			
			NSString * documentFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
			NSString * oldCountdownPath = [NSString stringWithFormat:@"%@/Countdown.plist", documentFolderPath];
			data = [NSData dataWithContentsOfFile:oldCountdownPath];
			
			if (!data) {// ...And if no file exist at ~/Documents/Countdown.plist, fetch default plist file from Closer bundle
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
			
			NSString * identifier = dictionary[@"identifier"];
			Countdown * aCountdown = [[Countdown alloc] initWithIdentifier:identifier];
			
			CountdownType type = [dictionary[@"type"] integerValue];
			if (type == CountdownTypeCountdown) {
				aCountdown.message = dictionary[@"message"];
			} else {
				NSArray * durations = dictionary[@"durations"];
				if (durations) [aCountdown addDurations:durations];
				aCountdown.durationIndex = [dictionary[@"durationIndex"] integerValue];
				aCountdown.promptState = [dictionary[@"prompt"] integerValue];
			}
			
			aCountdown.name = dictionary[@"name"];
			aCountdown.endDate = dictionary[@"endDate"];
			aCountdown.songID = dictionary[@"songID"];
			aCountdown.style = [dictionary[@"style"] integerValue];
			aCountdown.type = type;
            aCountdown.notificationCenter = (dictionary[@"notificationCenter"]) ? [dictionary[@"notificationCenter"] boolValue] : YES;
			
			[aCountdown activate];
			[_countdowns addObject:aCountdown];
		}
		[_countdowns sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"notificationCenter" ascending:NO] ]];
		
		[NSNotificationCenter.defaultCenter addObserverForName:CountdownDidUpdateNotification
														object:nil queue:NSOperationQueue.currentQueue
													usingBlock:^(NSNotification *note) {
														[self.class updateUserDefaults];
														CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
														CFNotificationCenterPostNotification(center, CFSTR("Darwin_CountdownDidUpdateNotification"), NULL, NULL, YES);
													}];
		[NSNotificationCenter.defaultCenter addObserverForName:CountdownDidSynchronizeNotification
														object:nil queue:NSOperationQueue.currentQueue
													usingBlock:^(NSNotification *note) {
														[self updateUserDefaults];
														
														NSPredicate * predicate = [NSPredicate predicateWithFormat:@"notificationCenter == YES"];
														NSArray * includedCountdowns = [_countdowns filteredArrayUsingPredicate:predicate];
														[[NCWidgetController widgetController] setHasContent:(includedCountdowns.count > 0)
																			   forWidgetWithBundleIdentifier:@"com.lisacintosh.closer.Widget"];
														
														CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
														CFNotificationCenterPostNotification(center, CFSTR("Darwin_CountdownDidSynchronizeNotification"), NULL, NULL, YES);
													}];
		if (_countdowns.count > 0) {
			[NSNotificationCenter.defaultCenter postNotificationName:CountdownDidSynchronizeNotification object:nil];
		}
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
		NSUInteger index = [userDefaults integerForKey:kLastSelectedPageIndex];
		Countdown * countdown = _countdowns[MIN(_countdowns.count - 1, index)];
		[sharedDefaults setObject:countdown.identifier forKey:@"selectedIdentifier"];
		[sharedDefaults synchronize];
	}
}

+ (void)synchronize
{
    [self synchronizeWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
			UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR_ALERT_TITLE", nil)
																			message:error.localizedDescription
																	 preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[alert dismissViewControllerAnimated:YES completion:nil]; }]];
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
        NSData * data = [NSPropertyListSerialization dataWithPropertyList:_propertyList
                                                                   format:NSPropertyListBinaryFormat_v1_0
                                                                  options:0
                                                                    error:&error];
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
                NSError * error = [NSError errorWithDomain:@"CountdownErrorDomain"
                                                      code:2
                                                  userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"WRITING_ERROR_ALERT_TITLE", nil) }];
                completionHandler(NO, error);
            }
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
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
		if ([aCountdown.identifier isEqualToString:identifier]) {
			return aCountdown;
		}
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
	[countdown activate];
	[_countdowns insertObject:countdown atIndex:index];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (void)addCountdown:(Countdown *)countdown
{
	[countdown activate];
	[_countdowns addObject:countdown];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (void)addCountdowns:(NSArray *)countdowns
{
	for (Countdown * countdown in countdowns)
		[countdown activate];
	
	[_countdowns addObjectsFromArray:countdowns];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		Countdown * countdown = _countdowns[fromIndex];
		[_countdowns removeObjectAtIndex:fromIndex];
		[_countdowns insertObject:countdown atIndex:toIndex];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
		[self synchronize];
	}
}

+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2
{
	[_countdowns exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (void)removeCountdown:(Countdown *)countdown
{
	[countdown remove];
	[countdown desactivate];
	[_countdowns removeObject:countdown];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (void)removeCountdownAtIndex:(NSInteger)index
{
	Countdown * countdown = _countdowns[index];
	[countdown remove];
	[countdown desactivate];
	[_countdowns removeObjectAtIndex:index];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	[self synchronize];
}

+ (NSArray *)styles
{
    return @[ NSLocalizedString(@"PAGE_STYLE_NIGHT", nil),
              NSLocalizedString(@"PAGE_STYLE_DAY", nil),
              NSLocalizedString(@"PAGE_STYLE_DAWN", nil),
              NSLocalizedString(@"PAGE_STYLE_OASIS", nil),
              NSLocalizedString(@"PAGE_STYLE_SPRING", nil) ];
}

#pragma mark - Countdown's Instance Methods

- (NSDictionary *)countdownToDictionary
{
	NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithCapacity:_countdowns.count];
	dictionary[@"name"] = self.name;
	
	if (self.type == CountdownTypeCountdown) {
		if (self.endDate) dictionary[@"endDate"] = self.endDate;
		if (self.message) dictionary[@"message"] = self.message;
	} else {
		if (self.durations) dictionary[@"durations"] = self.durations;
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

- (instancetype)init
{
	return [self initWithIdentifier:nil];
}

- (instancetype)initWithIdentifier:(NSString *)anIdentifier
{
	if ((self = [super init])) {
		if (!anIdentifier) {
			anIdentifier = [NSUUID UUID].UUIDString;
		}
		
		/* Don't call self.xxx to not call updateLocalNotification many times */
		_name = NSLocalizedString(@"NO_TITLE_PLACEHOLDER", nil);
		_endDate = nil;
		_message = @"";
		_songID = @"default";
		_style = 0;
		_type = CountdownTypeCountdown;
        _notificationCenter = YES;
		
		_identifier = anIdentifier;
		
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
		_name = aName;
		[self update];
	}
}

- (void)setMessage:(NSString *)aMessage
{
	if (aMessage && ![aMessage isEqualToString:_message]) {
		_message = aMessage;
		[self update];
	}
}

- (void)setEndDate:(NSDate *)aDate
{
	_endDate = aDate;
	_paused = (_endDate == nil);
	[self update];
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
		_style = style;
		[self update];
	}
}

- (void)setType:(CountdownType)newType
{
	if (_type != newType) {
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

#pragma mark - Timer Methods

- (void)setDurationIndex:(NSInteger)index
{
	if (self.durations.count > 0)
		_durationIndex = index % self.durations.count;
}

- (NSNumber *)currentDuration
{
	/* Return the current duration (at index "duratonIndex" if not out of bounds, else return the first duration if exists, else return "nil" */
	return (_durationIndex <= ((NSInteger)_durations.count - 1)) ? _durations[_durationIndex] : ((_durations.count > 0) ? _durations[0] : nil);
}

- (NSArray *)durations
{
	return _durations;
}

- (void)addDuration:(NSNumber *)duration
{
	if (!_durations)
		_durations = [[NSMutableArray alloc] initWithCapacity:5];
	
	[_durations addObject:duration];
}

- (void)addDurations:(NSArray *)someDurations
{
	if (!_durations)
		_durations = [[NSMutableArray alloc] initWithCapacity:5];
	
	[_durations addObjectsFromArray:someDurations];
}

- (void)setDuration:(NSNumber *)duration atIndex:(NSInteger)index
{
	_durations[index] = duration;
}

- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		NSNumber * duration = _durations[fromIndex];
		[_durations removeObjectAtIndex:fromIndex];
		[_durations insertObject:duration atIndex:toIndex];
	}
}

- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2
{
	[_durations exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)removeDurationAtIndex:(NSUInteger)index
{
	[_durations removeObjectAtIndex:index];
}

- (void)resetDurationIndex
{
	_durationIndex = 0;
}

- (void)resume
{
	if (_type == CountdownTypeTimer && _paused) {
		_endDate = [NSDate dateWithTimeIntervalSinceNow:_remaining];
		_remaining = 0.;
		_paused = NO;
		[self updateLocalNotification];
	}
}

- (void)pause
{
	if (_type == CountdownTypeTimer && !_paused) {
		_remaining = _endDate.timeIntervalSinceNow;
		_endDate = nil;
		_paused = YES;
		[self updateLocalNotification];
	}
}

- (void)reset
{
	if (_type == CountdownTypeTimer) {
		_endDate = [NSDate dateWithTimeIntervalSinceNow:self.currentDuration.doubleValue];
		_paused = NO;
		[self updateLocalNotification];
	}
}

#pragma mark Localized description methods

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index
{
	long seconds = _durations[index].longValue;
	long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
	long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
	long minutes = seconds / 60; seconds -= minutes * 60;
	
	NSInteger count = 0; if (days) count++; if (hours) count++; if (minutes) count++; if (seconds) count++;
	
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
	
	NSInteger count = 0; if (days) count++; if (hours) count++; if (minutes) count++; if (seconds) count++;
	
	NSMutableArray * components = [[NSMutableArray alloc] initWithCapacity:4];
	if (count > 2) {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld%@", days, NSLocalizedString(@"d", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld%@", hours, NSLocalizedString(@"h", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld%@", minutes, NSLocalizedString(@"m", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld%@", seconds, NSLocalizedString(@"s", nil)]];
	} else {
		if (days) [components addObject:[NSString stringWithFormat:@"%ld %@ ", days, (days > 1) ? NSLocalizedString(@"days", nil) : NSLocalizedString(@"day", nil)]];
		if (hours) [components addObject:[NSString stringWithFormat:@"%ld %@ ", hours, (hours > 1) ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil)]];
		if (minutes) [components addObject:[NSString stringWithFormat:@"%ld %@ ", minutes, NSLocalizedString(@"min", nil)]];
		if (seconds) [components addObject:[NSString stringWithFormat:@"%ld %@ ", seconds, NSLocalizedString(@"sec", nil)]];
	}
	
	return [components componentsJoinedByString:@", " withLastJoin:NSLocalizedString(@" and ", nil)]; // "12 min and 34 sec", "12d, 34h, 56m and 12s"
}


#pragma mark - isEqual Methods

- (BOOL)isEqual:(Countdown *)anotherCountdown
{
	return [self isEqualToCountdown:anotherCountdown];
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
	if (_type == CountdownTypeTimer)
		return [NSString stringWithFormat:@"<Countdown (Timer): 0x%p; name = %@; durations = %@; songID = %@>", self, _name, [_durations componentsJoinedByString:@","], _songID];
	else
		return [NSString stringWithFormat:@"<Countdown: 0x%p; name = %@; endDate = %@; songID = %@>", self, _name, _endDate, _songID];
}


#pragma mark - Memory Management

- (void)dealloc
{
    // Remove the notification
    [self remove];
}

@end
