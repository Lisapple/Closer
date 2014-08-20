//
//  SectionCalendarTableViewCell.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SectionCalendarTableViewCell.h"

@implementation _InternalSectionCalendarView

@synthesize CGColor;

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		self.clearsContextBeforeDrawing = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
	
	return self;
}

- (void)setCGColor:(CGColorRef)colorRef
{
	CGColorRelease(CGColor);
	CGColor = CGColorRetain(colorRef);
	
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	float radius = 10.;
	
	CGContextMoveToPoint(context, 0., radius);
	CGContextAddArcToPoint(context, 0., 0., radius, 0., radius);
	CGContextAddLineToPoint(context, rect.size.width - radius, 0.);
	CGContextAddArcToPoint(context, rect.size.width, 0., rect.size.width, radius, radius);
	CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
	CGContextAddLineToPoint(context, 0., rect.size.height);
	CGContextAddLineToPoint(context, 0., radius);
	CGContextClosePath(context);
	CGContextClip(context);
	
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	NSInteger number = (NSInteger)CGColorGetNumberOfComponents(CGColor);
	CGFloat * components = (CGFloat *)CGColorGetComponents(CGColor);
	
	/* Compute lighter color */
	CGFloat lighterComponents[4];
	for (int i = 0; i < number; i++) {
		lighterComponents[i] = components[i] + (1. - components[i]) / 2.;
	}
	
	CGColorRef lighterColorRef = CGColorCreate(colorSpace, lighterComponents);
	
	/* Compute darker color */
	CGFloat darkerComponents[4];
	for (int i = 0; i < 3; i++) {
		darkerComponents[i] = components[i] / 2.;
	}
	darkerComponents[3] = 0.8;
	
	CGColorRef darkerColorRef = CGColorCreate(colorSpace, darkerComponents);
	
	const CGFloat locations[3] = { 0., 19. / 22., 1.};// The 3px bottom are darker
	
	 CFMutableArrayRef colors = CFArrayCreateMutable(kCFAllocatorDefault, 3, NULL);
	 CFArrayAppendValue(colors, lighterColorRef);
	 CFArrayAppendValue(colors, CGColor);
	 CFArrayAppendValue(colors, darkerColorRef);
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CGColorSpaceRelease(colorSpace);
	CFRelease(colors);
	
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0., 0.), CGPointMake(0., rect.size.height), 0);
	CGGradientRelease(gradient);
	CGColorRelease(lighterColorRef);
	CGColorRelease(darkerColorRef);
}

@end

@implementation SectionCalendarTableViewCell

@synthesize CGColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
		_InternalSectionCalendarView * _internalSectionCalendarView = [[_InternalSectionCalendarView alloc] initWithFrame:self.frame];
		self.backgroundView = _internalSectionCalendarView;
    }
    return self;
}

- (void)setCGColor:(CGColorRef)colorRef
{
	CGColor = CGColorRetain(colorRef);
	
	_InternalSectionCalendarView * _internalSectionCalendarView = (_InternalSectionCalendarView *)self.backgroundView;
	_internalSectionCalendarView.CGColor = colorRef;
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	if (self.imageView.image) {
		
		CGRect frame = self.imageView.frame;
		frame.origin.x = 6.;
		self.imageView.frame = frame;
		
		frame = self.textLabel.frame;
		frame.origin.x = 25.;
		self.textLabel.frame = frame;
	}
}

@end
