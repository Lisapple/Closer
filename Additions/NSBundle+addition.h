//
//  NSBundle+addition.h
//  Closer
//
//  Created by Max on 1/17/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@interface NSBundle(addition)

- (NSString *)nameForSongWithID:(NSString *)songID;

- (NSString *)filenameForSongWithID:(NSString *)songID;
- (NSString *)pathForSongWithID:(NSString *)songID;
- (NSString *)pathForDefaultSong;

@end
