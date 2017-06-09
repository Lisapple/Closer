//
//  DurationPickerViewController.h
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "DurationPickerView.h"

@interface DurationPickerViewController : UITableViewController <DurationPickerViewDelegate, DurationPickerViewDataSource>

@property (nonatomic, strong) Countdown * countdown;
@property (nonatomic, assign) NSInteger durationIndex;

@end
