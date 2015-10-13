//
//  SongPickerViewController.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SongPickerViewController.h"

@interface SongPickerViewController ()

@property (nonatomic, strong) NSIndexPath * checkedIndexPath;
@property (nonatomic, strong) AVAudioPlayer * player;

@end

@implementation SongPickerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Sound", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
    
	NSString * path = [[NSBundle mainBundle] pathForResource:@"songs" ofType:@"plist"];
	_songs = [[NSMutableArray alloc] initWithContentsOfFile:path];
	
	self.songID = _countdown.songID;
	
	[_tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_countdown.songID = _songID;
	
	[_player pause];
	
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
		return _songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			if ([_songID isEqualToString:@"-1"]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				_checkedIndexPath = indexPath;
			}
			cell.textLabel.text = NSLocalizedString(@"None", nil);
		} else if (indexPath.row == 1) {
			if ([_songID isEqualToString:@"default"]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				_checkedIndexPath = indexPath;
			}
			cell.textLabel.text = NSLocalizedString(@"Default", nil);
		}
	} else {
		NSString * thisID = _songs[indexPath.row][@"ID"];
		if ([_songID isEqualToString:thisID]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			_checkedIndexPath = indexPath;
		}
		cell.textLabel.text = _songs[indexPath.row][@"Name"];
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath compare:_checkedIndexPath] != NSOrderedSame) {
		
		UITableViewCell * checkedCell = [aTableView cellForRowAtIndexPath:_checkedIndexPath];
		checkedCell.accessoryType = UITableViewCellAccessoryNone;// Uncheck old checked cell
		
		_checkedIndexPath = indexPath;
		
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		[_player pause];
		
		if (indexPath.section == 0) {
			if (indexPath.row == 0) { // "None"
				self.songID = @"-1";
			} else { // "Default"
				
				// Play the default song (from complete.caf)
				NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [NSBundle mainBundle].bundlePath];
				_player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
#if !TARGET_IPHONE_SIMULATOR
                /* This can crash on Simulator */
				[_player prepareToPlay];
				[_player play];
#endif
				self.songID = @"default";
			}
			
		} else if (indexPath.section == 1) {
			
			NSString * fileName = _songs[indexPath.row][@"Filename"];
			NSString * path = [NSString stringWithFormat:@"%@/Songs/%@", [NSBundle mainBundle].bundlePath, fileName];
			_player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                            error:nil];
#if !TARGET_IPHONE_SIMULATOR
			/* This can crash on Simulator */
			[_player prepareToPlay];
			[_player play];
#endif
			
			self.songID = _songs[indexPath.row][@"ID"];
		}
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
