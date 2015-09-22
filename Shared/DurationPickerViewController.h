//
//  DurationPickerViewController.h
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import <UIKit/UIKit.h>

#import "DurationPickerView.h"

@interface DurationPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, DurationPickerViewDelegate, DurationPickerViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) Countdown * countdown;
@property (nonatomic, assign) NSInteger durationIndex;

@end
