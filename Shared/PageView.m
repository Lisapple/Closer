//
//  PageView.m
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import "PageView.h"

@implementation PageView

@synthesize countdown;
@synthesize position;
@synthesize delegate;
@synthesize orientation;

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.orientation = [[UIApplication sharedApplication] statusBarOrientation];
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)update
{
	/* Subsclasses must implement it */
}

#pragma Page Resources Management

- (void)load
{
	/* Subsclasses must implement it */
}

- (void)unload
{
	/* Subsclasses must implement it */
}

@end
