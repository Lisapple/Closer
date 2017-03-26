//
//  UIViewController+addition.h
//  Closer
//
//  Created by Max on 18/03/2017.
//
//

@interface UIViewController (addition)

/// Show an alert with localized error description, if any error given.
- (void)presentError:(nullable NSError *)error;

@end
