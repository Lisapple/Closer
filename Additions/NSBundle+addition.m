//
//  NSBundle+addition.m
//  Closer
//
//  Created by Max on 1/17/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSBundle+addition.h"


@implementation NSBundle(addition)

- (NSString *)nameForSongWithID:(NSString *)songID
{
	if ([songID isEqualToString:@"-1"]) {
		return nil;
	} else if ([songID isEqualToString:@"default"]) {
		return NSLocalizedString(@"Default", nil);
	} else {
		
		NSString * path = [[NSBundle mainBundle] pathForResource:@"songs" ofType:@"plist"];
		NSArray * songs = [[NSArray alloc] initWithContentsOfFile:path];
		
		NSString * name = nil;
		for (NSDictionary * attributes in songs) {
			if ([attributes[@"ID"] isEqualToString:songID]) {
				name = attributes[@"Name"];
				break;
			}
		}
		
		return name;
	}
	
	return nil;
}

- (NSString *)filenameForSongWithID:(NSString *)songID
{
	NSString * path = [[NSBundle mainBundle] pathForResource:@"songs" ofType:@"plist"];
	NSArray * songs = [[NSArray alloc] initWithContentsOfFile:path];
	
	NSString * filename = nil;
	for (NSDictionary * attributes in songs) {
		if ([attributes[@"ID"] isEqualToString:songID]) {
			filename = attributes[@"Filename"];
			break;
		}
	}
	
	
	return filename;
}

- (NSString *)pathForSongWithID:(NSString *)songID
{
	NSString * filename = [self filenameForSongWithID:songID];
	if (!filename)
		return nil;
	
	return [NSString stringWithFormat:@"%@/Songs/%@", [[NSBundle mainBundle] bundlePath], filename];
}

- (NSString *)pathForDefaultSong
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	return [self pathForSongWithID:[userDefaults objectForKey:@"songID"]];
}

@end
