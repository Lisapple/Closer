//
//  SettingsViewController.h
//  Closer
//
//  Created by Max on 21/01/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SettingsType) {
	SettingsTypeNone,
	
	SettingsTypeName,
	SettingsTypeDateAndTime,
	SettingsTypeMessage,
	SettingsTypeDurations,
	SettingsTypeSong,
	SettingsTypeTheme
};

@protocol SettingsControllerProtocol <NSObject>

- (UIViewController *)showSettingsType:(SettingsType)setting animated:(BOOL)animated;

@end