//
//  Countdown.m
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "Countdown.h"

#import "NSBundle+addition.h"
#import "NSArray+addition.h"

@implementation Countdown

@synthesize name;
@synthesize endDate;
@synthesize message;
@synthesize songID;
@synthesize style;
@synthesize type = _type;
@synthesize promptState = _promptState;
@synthesize durationIndex = _durationIndex;

@synthesize identifier;

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
		NSString * preferencesFolderPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
		_countdownsListPath = [[NSString alloc] initWithFormat:@"%@/Preferences/Countdowns.plist", preferencesFolderPath];
		
		NSString * errorString = nil;
		NSData * data = [NSData dataWithContentsOfFile:_countdownsListPath];
		if (!data) {// If no Countdowns.plist have been found, look up at ~/Documents/Countdown.plist ...
			
			NSString * documentFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			NSString * oldCountdownPath = [NSString stringWithFormat:@"%@/Countdown.plist", documentFolderPath];
			data = [NSData dataWithContentsOfFile:oldCountdownPath];
			
			if (!data) {// ...And if no file exist at ~/Documents/Countdown.plist, fetch default plist file from Closer bundle
				NSString * path = [[NSBundle mainBundle] pathForResource:@"Countdown" ofType:@"plist"];
				data = [NSData dataWithContentsOfFile:path];
			}
			
			// Force to move the current (or default) countdown list file to ~/Library/Preferences/
			NSError * error = nil;
			BOOL success = [data writeToFile:_countdownsListPath options:NSDataWritingAtomic error:&error];
			
			if (!success) {
				NSLog(@"error on writing file to : %@ => [%@]", _countdownsListPath, [error localizedDescription]);
			}
			
			// And then, remove the file at ~/Documents/Countdown.plist to not show it on iTunes Sharing */
			if ([[NSFileManager defaultManager] fileExistsAtPath:oldCountdownPath]) {
				error = nil;
				success = [[NSFileManager defaultManager] removeItemAtPath:oldCountdownPath error:&error];
				
				if (!success) {
					NSLog(@"error when removing file to : %@ => [%@]", _countdownsListPath, [error localizedDescription]);
				}
			}
		}
		
		NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
		
		_propertyList = [NSPropertyListSerialization propertyListFromData:data
														 mutabilityOption:NSPropertyListMutableContainersAndLeaves
																   format:&format
														 errorDescription:&errorString];
		
		if (![_propertyList isKindOfClass:[NSMutableArray class]])
			[NSException raise:@"CountdownException" format:@"Countdown.plist should be an mutable array based format."];
		
		
		_countdowns = [[NSMutableArray alloc] initWithCapacity:_propertyList.count];
		for (NSDictionary * dictionary in _propertyList) {
			
			NSString * identifier = [dictionary objectForKey:@"identifier"];
			Countdown * aCountdown = [[Countdown alloc] initWithIdentifier:identifier];
			
			CountdownType type = [[dictionary objectForKey:@"type"] integerValue];
			if (type == CountdownTypeDefault) {
				aCountdown.message = [dictionary objectForKey:@"message"];
			} else {
				NSArray * durations = [dictionary objectForKey:@"durations"];
				if (durations) [aCountdown addDurations:durations];
				aCountdown.durationIndex = [[dictionary objectForKey:@"durationIndex"] integerValue];
				
				aCountdown.promptState = [[dictionary objectForKey:@"prompt"] integerValue];
			}
			
			aCountdown.name = [dictionary objectForKey:@"name"];
			aCountdown.endDate = [dictionary objectForKey:@"endDate"];
			aCountdown.songID = [dictionary objectForKey:@"songID"];
			aCountdown.style = [[dictionary objectForKey:@"style"] integerValue];
			aCountdown.type = type;
			
			[aCountdown activate];
			[_countdowns addObject:aCountdown];
		}
		
		if (_countdowns.count > 0)
			[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	}
}

+ (void)synchronize
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[Countdown synchronize_async];
	});
}

+ (void)synchronize_async
{
	@synchronized(_countdowns) {
		[_propertyList removeAllObjects];
		for (Countdown * countdown in _countdowns) {
			NSDictionary * dictionary = [countdown _countdownToDictionary];
			[_propertyList addObject:dictionary];
		}
	}
	
	NSString * errorString = nil;
	NSData * data = [NSPropertyListSerialization dataFromPropertyList:_propertyList
															   format:NSPropertyListBinaryFormat_v1_0
													 errorDescription:&errorString];
	
	if (!data) {
		
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"READING_ERROR_ALERT_TITLE", nil)
															 message:NSLocalizedString(@"READING_ERROR_ALERT_MESSAGE", nil)
															delegate:nil
												   cancelButtonTitle:nil
												   otherButtonTitles:nil, nil];
		[alertView show];
		
		NSLog(@"Error when serialize property list : %@", errorString);
		return;
	}
	
	NSError * error = nil;
	BOOL succeed = [data writeToFile:_countdownsListPath options:NSDataWritingAtomic error:&error];// Write data atomically
	if (!succeed && error) {
		
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"WRITING_ERROR_ALERT_MESSAGE %@", nil), [[UIDevice currentDevice] localizedModel]];
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WRITING_ERROR_ALERT_TITLE", nil)
															 message:message
															delegate:nil
												   cancelButtonTitle:nil
												   otherButtonTitles:nil];
		[alertView show];
		
		NSLog(@"error on writing file to : %@ => [%@]", _countdownsListPath, [error localizedDescription]);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
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
	return (Countdown *)[_countdowns objectAtIndex:index];
}

+ (NSInteger)indexOfCountdown:(Countdown *)countdown
{
	return [_countdowns indexOfObject:countdown];
}

+ (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index
{
	[_countdowns insertObject:countdown atIndex:index];
}

+ (void)addCountdown:(Countdown *)countdown
{
	[countdown activate];
	[_countdowns addObject:countdown];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
}

+ (void)addCountdowns:(NSArray *)countdowns
{
	for (Countdown * countdown in countdowns)
		[countdown activate];
	
	[_countdowns addObjectsFromArray:countdowns];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
}

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		Countdown * countdown = _countdowns[fromIndex];
		[_countdowns removeObjectAtIndex:fromIndex];
		[_countdowns insertObject:countdown atIndex:toIndex];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
	}
}

+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2
{
	[_countdowns exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
}

+ (void)removeCountdown:(Countdown *)countdown
{
	[countdown removeLocalNotification];
	[_countdowns removeObject:countdown];
	[countdown desactivate];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
}

+ (void)removeCountdownAtIndex:(NSInteger)index
{
	Countdown * countdown = [_countdowns objectAtIndex:index];
	[countdown removeLocalNotification];
	[countdown desactivate];
	[_countdowns removeObjectAtIndex:index];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidSynchronizeNotification object:nil];
}

+ (NSArray *)styles
{
	return [NSArray arrayWithObjects:NSLocalizedString(@"DEFAULT_STYLE", nil),
			NSLocalizedString(@"LCD_STYLE", nil),
			NSLocalizedString(@"BOARD_STYLE", nil),
			NSLocalizedString(@"PAPER_STYLE", nil),
			NSLocalizedString(@"TIMES_STYLE", nil), nil];
}

#pragma mark - Countdown's Instance Methods

- (NSMutableDictionary *)_countdownToDictionary
{
	NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	[dictionary setObject:self.name forKey:@"name"];
	
	if (self.type == CountdownTypeDefault) {
		if (self.endDate) [dictionary setObject:self.endDate forKey:@"endDate"];
		if (self.message) [dictionary setObject:self.message forKey:@"message"];
	} else {
		if (durations) [dictionary setObject:durations forKey:@"durations"];
		[dictionary setObject:[NSNumber numberWithInteger:self.durationIndex] forKey:@"durationIndex"];
		
		if (self.endDate) [dictionary setObject:self.endDate forKey:@"endDate"];
		[dictionary setObject:[NSNumber numberWithInteger:self.promptState] forKey:@"prompt"];
	}
	
	[dictionary setObject:self.songID forKey:@"songID"];
	[dictionary setObject:self.identifier forKey:@"identifier"];
	[dictionary setObject:[NSNumber numberWithInteger:self.style] forKey:@"style"];
	[dictionary setObject:[NSNumber numberWithInteger:self.type] forKey:@"type"];
	
	return dictionary;
}

- (id)initWithIdentifier:(NSString *)anIdentifier
{
	if ((self = [super init])) {
		if (anIdentifier) {
			identifier = anIdentifier;
		} else {
			CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
			CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
			identifier = (__bridge NSString *)uuidString;
			CFRelease(uuidString);
			CFRelease(uuidRef);
		}
		
		/* Don't call self.xxx to not call updateLocalNotification many times */
		name = NSLocalizedString(@"NO_TITLE_PLACEHOLDER", nil);
		endDate = nil;
		message = @"";
		songID = @"default";
		style = 0;
		_type = CountdownTypeDefault;
		
		identifier = anIdentifier;
		
		[self updateLocalNotification];
	}
	
	return self;
}

- (id)init
{
	if ((self = [super init])) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		identifier = (__bridge NSString *)uuidString;
		CFRelease(uuidString);
		CFRelease(uuidRef);
		
		/* Don't call self.xxx to not call updateLocalNotification many times */
		name = NSLocalizedString(@"NO_TITLE_PLACEHOLDER", nil);
		endDate = nil;
		message = @"";
		songID = @"default";
		style = 0;
		_type = CountdownTypeDefault;
		
		[self updateLocalNotification];
	}
	
	return self;
}

- (void)activate
{
	active = YES;
}

- (void)desactivate
{
	active = NO;
}

- (UILocalNotification *)localNotification
{
	NSArray * allLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
	for (UILocalNotification * localNotif in allLocalNotifications) {
		
		NSString * anIdentifier = [localNotif.userInfo objectForKey:@"identifier"];
		if ([anIdentifier isEqualToString:self.identifier]) {
			return localNotif;// Return the localNotification
		}
	}
	
	return nil;
}

- (UILocalNotification *)createLocalNotification
{
	NSDebugLog(@"Create new local notification for countdown : %@ => %@", self.name, [endDate description]);
	UILocalNotification * localNotif = [[UILocalNotification alloc] init];
	
	localNotif.timeZone = [NSTimeZone localTimeZone];
	localNotif.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.identifier, @"identifier", nil];
	
	return localNotif;
}

- (void)updateLocalNotification
{
	if (active) {
		dispatch_async(dispatch_get_current_queue(), ^{
			if (endDate && endDate.timeIntervalSinceNow > 0.) {
				
				UILocalNotification * localNotif = [self localNotification];
				if (localNotif) {
					[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
				} else {
					localNotif = [self createLocalNotification];
				}
				
				localNotif.fireDate = self.endDate;
				
				NSString * messageString = message;
				if (!message || [message isEqualToString:@""]) {// If no message, show the default message
					if (self.style == CountdownTypeTimer) {
						if (name)// If name was set, add it to default message
							messageString = [NSString stringWithFormat:NSLocalizedString(@"TIMER_FINISHED_MESSAGE %@", nil), self.name];
						else // Else if wasn't set, just show the default message
							messageString = NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil);
					} else {
						if (name) messageString = [NSString stringWithFormat:NSLocalizedString(@"COUNTDOWN_FINISHED_MESSAGE %@", nil), self.name];
						else messageString = NSLocalizedString(@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE", nil);
					}
				}
				localNotif.alertBody = messageString;
				
				localNotif.repeatInterval = 0;
				localNotif.hasAction = YES;
				
				if ([self.songID isEqualToString:@"-1"]) {// Don't play any sound ("-1" means "none")
					
				} else if ([self.songID isEqualToString:@"default"]) {// Play default sound
					localNotif.soundName = UILocalNotificationDefaultSoundName;
					
				} else {// Play other sound from Songs folder
					NSString * songPath = [NSString stringWithFormat:@"Songs/%@", [[NSBundle mainBundle] filenameForSongWithID:self.songID]];
					localNotif.soundName = songPath;
				}
				
				/* localNotif.userInfo => don't change userInfo, it alrealdy contains identifier */
				
				NSDebugLog(@"updateLocalNotification: (%@ %@)", localNotif.fireDate, localNotif.alertBody);
				
				[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
			} else {
				/* Remove the notification */
				UILocalNotification * localNotif = [self localNotification];
				if (localNotif) {
					[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
				}
			}
			
			/* Send a notification from the countdown/timer */
			[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidUpdateNotification
																object:self];
		});
	}
}

- (void)removeLocalNotification
{
	UILocalNotification * localNotif = [self localNotification];
	if (localNotif)
		[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
}

- (void)setName:(NSString *)aName
{
	if (aName && ![aName isEqualToString:name]) {
		name = aName;
	}
}

- (void)setMessage:(NSString *)aMessage
{
	if (aMessage && ![aMessage isEqualToString:message]) {
		message = aMessage;
		
		[self updateLocalNotification];
	}
}

- (void)setEndDate:(NSDate *)aDate
{
	if (aDate && ![aDate isEqualToDate:endDate]) {
		endDate = aDate;
		
		[self updateLocalNotification];
		NSDebugLog(@"set end date: %@", aDate);
	}
}

- (void)setSongID:(NSString *)aSongID
{
	if (aSongID && ![aSongID isEqualToString:songID]) {
		songID = aSongID;
		
		[self updateLocalNotification];
	}
}

- (void)setType:(CountdownType)newType
{
	if (_type != newType) {
		_type = newType;
		
		[self updateLocalNotification];
	}
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
	return (_durationIndex <= ((NSInteger)durations.count - 1)) ? durations[_durationIndex] : ((durations.count > 0) ? durations[0] : nil);
}

- (NSArray *)durations
{
	return durations;
}

- (void)addDuration:(NSNumber *)duration
{
	if (!durations)
		durations = [[NSMutableArray alloc] initWithCapacity:5];
	
	[durations addObject:duration];
}

- (void)addDurations:(NSArray *)someDurations
{
	if (!durations)
		durations = [[NSMutableArray alloc] initWithCapacity:5];
	
	[durations addObjectsFromArray:someDurations];
}

- (void)setDuration:(NSNumber *)duration atIndex:(NSInteger)index
{
	[durations replaceObjectAtIndex:index withObject:duration];
}

- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	if (fromIndex != toIndex) {
		NSNumber * duration = durations[fromIndex];
		[durations removeObjectAtIndex:fromIndex];
		[durations insertObject:duration atIndex:toIndex];
	}
}

- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2
{
	[durations exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)removeDurationAtIndex:(NSUInteger)index
{
	[durations removeObjectAtIndex:index];
}

- (void)resetDurationIndex
{
	_durationIndex = 0;
}

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index
{
	long seconds = [durations[index] longValue];
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
	
	return [components componentsJoinedByString:@", " andLastString:NSLocalizedString(@" and ", nil)]; // "12 minutes and 34 seconds", "12 days, 34 hours, 56 min and 12 sec"
}

- (NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index
{
	long seconds = [durations[index] longValue];
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
	
	return [components componentsJoinedByString:@", " andLastString:NSLocalizedString(@" and ", nil)]; // "12 min and 34 sec", "12d, 34h, 56m and 12s"
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
		return [NSString stringWithFormat:@"<Countdown (Timer): 0x%p; name = %@; durations = %@; songID = %@>", self, name, [durations componentsJoinedByString:@","], songID];
	else
		return [NSString stringWithFormat:@"<Countdown: 0x%p; name = %@; endDate = %@; songID = %@>", self, name, endDate, songID];
}


#pragma mark - Memory Management

- (void)dealloc
{
	self.name = nil;
	self.endDate = nil;
	self.message = nil;
	self.songID = nil;
	
	identifier = nil;
	durations = nil;
}

@end
