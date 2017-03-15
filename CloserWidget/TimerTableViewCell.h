//
//  TimerTableViewCell.h
//  Closer
//
//  Created by Max on 11/02/15.
//
//

@import UIKit;
@import NotificationCenter;

@interface TimerTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign) NSInteger duration, remaining;

@end
