//
//  ViewController.m
//
//  Created by Lisacintosh on 10/01/2017.
//
//

#import "ViewController.h"
#import "AProposViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoDark];
	[button addTarget:self action:@selector(presentAboutAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	// Center button in center of view
	button.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addConstraints:@[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
																 toItem:button attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
								 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
																 toItem:button attribute:NSLayoutAttributeCenterY multiplier:1 constant:0] ]];
}

- (void)presentAboutAction:(id)sender
{
	ApplicationLicenseType license = ApplicationLicenseTypePublicDomain;
	AProposViewController * controller = [[AProposViewController alloc] initWithLicenseType:license];
	controller.author = @"Lisacintosh";
	[controller setURLsStrings:@[ @"appstore.com/lisacintosh",
								  @"http://support.lisacintosh.com",
								  @"http://lisacintosh.com" ]];
	
	controller.repositoryURL = [NSURL URLWithString:@"https://github.com/lisapple/a-propos"];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	[self presentViewController:navigationController animated:YES completion:nil];
}

@end
