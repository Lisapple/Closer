//
//  SongPickerViewController.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SongPickerViewController.h"

@implementation SongPickerViewController

@synthesize tableView;

@synthesize songs;
@synthesize songID;

@synthesize countdown;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Sound", nil);
	self.view.tintColor = [UIColor blackColor];
	
	tableView.delegate = self;
	tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
	NSString * path = [[NSBundle mainBundle] pathForResource:@"songs" ofType:@"plist"];
	songs = [[NSMutableArray alloc] initWithContentsOfFile:path];
	
	self.songID = countdown.songID;
	
	[tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	countdown.songID = songID;
	
	[player pause];
	
	[Countdown synchronize];
	
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;// Return 2 for the "no song" and "default" section and songs list section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 2;// "no song" and "default"
	else
		return songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			if ([songID isEqualToString:@"-1"]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				checkedIndexPath = indexPath;
			}
			
			cell.textLabel.text = NSLocalizedString(@"None", nil);
			
		} else if (indexPath.row == 1) {
			
			if ([songID isEqualToString:@"default"]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				checkedIndexPath = indexPath;
			}
			
			cell.textLabel.text = NSLocalizedString(@"Default", nil);
		}
		
	} else {
		
		NSString * thisID = songs[indexPath.row][@"ID"];
		if ([songID isEqualToString:thisID]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			checkedIndexPath = indexPath;
		}
		
		cell.textLabel.text = songs[indexPath.row][@"Name"];
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath compare:checkedIndexPath] != NSOrderedSame) {
		
		UITableViewCell * checkedCell = [aTableView cellForRowAtIndexPath:checkedIndexPath];
		checkedCell.accessoryType = UITableViewCellAccessoryNone;// Uncheck old checked cell
		
		checkedIndexPath = indexPath;
		
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		[player pause];
		
		if (indexPath.section == 0) {
			if (indexPath.row == 0) { // "None"
				self.songID = @"-1";
			} else { // "Default"
				
				// Play the default song (from complete.caf)
				NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [NSBundle mainBundle].bundlePath];
				player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
#if !TARGET_IPHONE_SIMULATOR
                /* This can crash on Simulator */
				[player prepareToPlay];
				[player play];
#endif
				self.songID = @"default";
			}
			
		} else if (indexPath.section == 1) {
			
			NSString * fileName = songs[indexPath.row][@"Filename"];
			NSString * path = [NSString stringWithFormat:@"%@/Songs/%@", [NSBundle mainBundle].bundlePath, fileName];
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                            error:nil];
#if !TARGET_IPHONE_SIMULATOR
			/* This can crash on Simulator */
			[player prepareToPlay];
			[player play];
#endif
			
			self.songID = songs[indexPath.row][@"ID"];
		}
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
