//
//  MyDatePicker.m
//  Closer
//
//  Created by Max on 3/10/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MyDatePicker.h"

@implementation MyPickerView

- (id)initWithFrame: (CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		for (UIView * subview in self.subviews) {
			subview.frame = self.bounds;
		}
	}
	return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder {
	if (self = [super initWithCoder: aDecoder]) {
		for (UIView * subview in self.subviews) {
			subview.frame = self.bounds;
		}
	}
	return self;
}

@end


@implementation MyDatePicker

- (id)initWithFrame: (CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		for (UIView * subview in self.subviews) {
			subview.frame = self.bounds;
		}
	}
	return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder {
	if (self = [super initWithCoder: aDecoder]) {
		for (UIView * subview in self.subviews) {
			subview.frame = self.bounds;
		}
	}
	return self;
}

@end