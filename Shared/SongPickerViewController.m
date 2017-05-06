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

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) { }
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Sound", nil);
	
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"CellID"];
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"songs" ofType:@"plist"];
	_songs = [[NSMutableArray alloc] initWithContentsOfFile:path];
	
	self.songID = _countdown.songID;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	_countdown.songID = _songID;
	[Countdown synchronize];
	[_player pause];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2; // Return 2 for the "no song" and "default" section and songs list section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 2; // "no song" and "default"
	else
		return _songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"CellID"];
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	if (indexPath.section == 0) {
		if /**/ (indexPath.row == 0) {
			if ([_songID isEqualToString:@"-1"]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				_checkedIndexPath = indexPath;
			}
			cell.textLabel.text = NSLocalizedString(@"None", nil);
		}
		else if (indexPath.row == 1) {
			if ([_songID isEqualToString:CountdownDefaultSoundName]) {
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

#pragma mark - Table view delegate

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
			if (indexPath.row == 0) // "None"
				self.songID = @"-1";
			else { // "Default"
				
				// Play the default song (from complete.caf)
				NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [NSBundle mainBundle].bundlePath];
				_player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
#if !TARGET_IPHONE_SIMULATOR
				/* This can crash on Simulator */
				[_player prepareToPlay];
				[_player play];
#endif
				self.songID = CountdownDefaultSoundName;
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
	
	if (indexPath.section == 0 && indexPath.row == 0) // "None"
		[self.navigationController popViewControllerAnimated:YES];
}

@end
