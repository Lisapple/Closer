//
//  NSObject+additions.m
//  Closer
//
//  Created by Max on 23/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+additions.h"

@implementation _AnimationBlock

@end

@interface _AnimationHelper ()
{
	CADisplayLink * _link;
}

@property (atomic, strong) NSMutableArray * animationBlocks;

@end

@implementation _AnimationHelper

+ (_AnimationHelper *)defaultHelper
{
	static _AnimationHelper * helper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		helper = [[_AnimationHelper alloc] init];
	});
	return helper;
}

- (instancetype)init
{
	if ((self = [super init])) {
		_link = [[UIScreen mainScreen] displayLinkWithTarget:self
													selector:@selector(updateScreen:)];
		[_link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		_link.paused = YES;
		_animationBlocks = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (void)addAnimationWithUpdateBlock:(_AnimationBlockUpdateHandler)updateHandler
						   duration:(NSTimeInterval)duration
						 completion:(_AnimationBlockCompletionHandler)completion
{
	_AnimationBlock * block = [[_AnimationBlock alloc] init];
	block.updateBlock = updateHandler;
	block.duration = duration;
	block.completionBlock = completion;
	block.progression = 0.;
	[_animationBlocks addObject:block];
	
	if (_animationBlocks.count > 0)
		[self startUpdating];
}

- (void)updateScreen:(CADisplayLink *)sender
{
	static dispatch_queue_t queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queue = dispatch_queue_create("com.lisacintosh.closer.update-screen", DISPATCH_QUEUE_CONCURRENT); });
	
	for (_AnimationBlock * block in self.animationBlocks.mutableCopy) {
		
		dispatch_async(queue, ^{
			block.progression += _link.duration / block.duration;
			
			if (block.updateBlock)
				dispatch_async(queue, ^{ block.updateBlock(MIN(block.progression, 1.)); });
			
			if (block.progression >= 1.) {
				if (block.completionBlock)
					dispatch_async(queue, ^{ block.completionBlock(); });
				
				@synchronized(self.animationBlocks) {
					[self.animationBlocks removeObjectIdenticalTo:block];
				}
			}
		});
	}
	
	if (self.animationBlocks.count == 0)
		[self stopUpdating];
}

- (void)startUpdating
{
	_link.paused = NO;
}

- (void)stopUpdating
{
	_link.paused = YES;
}

@end


@implementation NSObject (addition)

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration
{
	[self animationBlock:block duration:duration completion:NULL];
}

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
	if (duration <= 0.)
		return ;
	[[_AnimationHelper defaultHelper] addAnimationWithUpdateBlock:block duration:duration completion:completion];
}

+ (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end

