//
//  TimerTableViewCell.h
//  Closer
//
//  Created by Max on 11/02/15.
//
//

#import <UIKit/UIKit.h>
#import <NotificationCenter/NotificationCenter.h>

@interface TimerTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign) NSInteger duration, remaining;

@end
