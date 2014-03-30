//
//  SongPickerViewController.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class Countdown;

@interface SongPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView * tableView;
	NSIndexPath * checkedIndexPath;
	
	NSMutableArray * songs;
	NSString * songID;
	
	Countdown * countdown;
	
	AVAudioPlayer * player;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) NSMutableArray * songs;
@property (nonatomic, strong) NSString * songID;

@property (nonatomic, strong) Countdown * countdown;

@end
