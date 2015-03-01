//
//  CountdownTableViewCell.h
//  Closer
//
//  Created by Max on 31/01/15.
//
//

#import <UIKit/UIKit.h>
#import <NotificationCenter/NotificationCenter.h>

@interface CountdownTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * endDate;

@end
