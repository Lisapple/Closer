//
//  DeleteTableViewCell.m
//  Closer
//
//  Created by Max on 27/02/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "DeleteTableViewCell.h"

#import "UIColor+addition.h"

@implementation _InternalDeleteView

@synthesize selected = _selected;

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		self.clearsContextBeforeDrawing = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
	
	return self;
}

- (void)setSelected:(BOOL)flag
{
	_selected = flag;
	
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
	CGContextAddLineToPoint(context, rect.size.width, rect.size.height - radius);
	CGContextAddArcToPoint(context, rect.size.width, rect.size.height, rect.size.width - radius, rect.size.height, radius);
	CGContextAddLineToPoint(context, radius, rect.size.height);
	CGContextAddArcToPoint(context, 0., rect.size.height, 0., rect.size.height - radius, radius);
	CGContextAddLineToPoint(context, 0., radius);
	CGContextClosePath(context);
	
	CGPathRef path = CGContextCopyPath(context);
	
	CGContextClip(context);
	
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	const CGFloat locations[4] = { 0., 0.5, 0.5, 1. };
	
	CFMutableArrayRef colors = CFArrayCreateMutable(kCFAllocatorDefault, 4, &kCFTypeArrayCallBacks);
	if (_selected) {
		
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.645 green:0.035 blue:0.004 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.555 green:0.023 blue:0.000 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.539 green:0.000 blue:0.000 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.680 green:0.059 blue:0.016 alpha:1.].CGColor);
		
		/*
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.645 green:0.035 blue:0.004 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.555 green:0.023 blue:0.000 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.539 green:0.000 blue:0.000 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.680 green:0.059 blue:0.016 alpha:1.].CGColor));
		*/
	} else {
		/* My style */
		/*
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.895 green:0.285 blue:0.254 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.805 green:0.250 blue:0.230 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.739 green:0.192 blue:0.165 alpha:1.].CGColor));
		CFArrayAppendValue(colors, CGColorRetain([UIColor colorWithRed:0.950 green:0.259 blue:0.216 alpha:1.].CGColor));
		 */
		
		// @TODO: Try a plain red background-color ("-[UIColor redColor]")
		
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.895 green:0.285 blue:0.254 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.805 green:0.250 blue:0.230 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.739 green:0.192 blue:0.165 alpha:1.].CGColor);
		CFArrayAppendValue(colors, [UIColor colorWithRed:0.950 green:0.259 blue:0.216 alpha:1.].CGColor);
	}
	
	/* Apple delete button's cell style
	 CFArrayAppendValue(colors, [UIColor colorWithRed:0.827 green:0.471 blue:0.486 alpha:1.].CGColor);
	 CFArrayAppendValue(colors, [UIColor colorWithRed:0.655 green:0.212 blue:0.224 alpha:1.].CGColor);
	 CFArrayAppendValue(colors, [UIColor colorWithRed:0.592 green:0.122 blue:0.122 alpha:1.].CGColor);
	 CFArrayAppendValue(colors, [UIColor colorWithRed:0.592 green:0.122 blue:0.122 alpha:1.].CGColor);
	 */
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0., 0.), CGPointMake(0., rect.size.height), 0);
	CGGradientRelease(gradient);
	
	CGColorSpaceRelease(colorSpace);
	CFRelease(colors);
	
	/*
	for (int i = 0; i < CFArrayGetCount(colors); i++) {
		CGColorRelease((CGColorRef)CFArrayGetValueAtIndex(colors, i));
	}
	*/
	
	CGContextAddPath(context, path);
	
	[[UIColor whiteColor] setStroke];
	CGContextSetLineWidth(context, 4.);
	CGContextStrokePath(context);
	
	CGPathRelease(path);
}

@end

@implementation DeleteTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
		_InternalDeleteView * _internalDeleteView = [[_InternalDeleteView alloc] initWithFrame:self.frame];
		self.backgroundView = _internalDeleteView;
		
		self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	
	((_InternalDeleteView *)self.backgroundView).selected = highlighted;
}

@end
