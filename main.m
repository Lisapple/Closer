//
//  main.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Phone.h"
#import "CloserAppDelegate_Pad.h"

int main(int argc, char *argv[]) {
	
	@autoreleasepool {
		Class class = TARGET_IS_IPAD() ? CloserAppDelegate_Pad.class : CloserAppDelegate_Phone.class;
		return UIApplicationMain(argc, argv, nil, NSStringFromClass(class));
	}
}
