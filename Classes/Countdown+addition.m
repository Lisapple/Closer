//
//  Countdown+Countdown_addition.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Countdown+addition.h"

@implementation Countdown (addition)

+ (Countdown *)countdownWithEvent:(EKEvent *)event
{
	Countdown * countdown = [[Countdown alloc] init];
	countdown.name = event.title;
	countdown.endDate = event.startDate;
	countdown.message = event.notes;
	
	return countdown;
}

@end
