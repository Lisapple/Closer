//
//  UIViewController+addition.m
//  Closer
//
//  Created by Max on 18/03/2017.
//
//

#import "UIViewController+addition.h"

@implementation UIViewController (addition)

- (void)presentError:(nullable NSError *)error
{
	if (error) {
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"generic.error", nil)
																		message:error.localizedDescription
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil)
												  style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

@end
