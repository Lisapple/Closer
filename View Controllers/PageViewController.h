//
//  PageViewController.h
//  Closer
//
//  Created by Max on 13/02/16.
//
//

@interface PageViewController : UIViewController

@property (nonatomic, strong, readonly, nonnull) Countdown * countdown;

- (nonnull instancetype)initWithCountdown:(nonnull Countdown *)countdown;

@end
