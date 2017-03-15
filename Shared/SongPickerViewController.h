//
//  SongPickerViewController.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import AudioToolbox;
@import AVFoundation;

@class Countdown;

@interface SongPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) NSMutableArray <NSDictionary *> * songs;
@property (nonatomic, strong) NSString * songID;

@property (nonatomic, strong) Countdown * countdown;

@end
