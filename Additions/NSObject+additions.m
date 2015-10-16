//
//  NSObject+addition.m
//  Elsas Gone
//
//  Created by Max on 7/23/14.
//  Copyright (c) 2014 Lisacintosh. All rights reserved.
//

#import "NSObject+additions.h"

@implementation _AnimationBlock

- (instancetype)init
{
	if ((self = [self initWithIdentifier:0])) { }
	return self;
}

- (instancetype)initWithIdentifier:(NSUInteger)identifier
{
	if ((self = [super init])) {
		_identifier = identifier;
	}
	return self;
}

- (void)cancel
{
	_isCancelled = YES;
	_repeats = NO;
	_progression = 0.;
}

@end

@interface _AnimationHelper ()

@property (atomic, strong) CADisplayLink * link;
@property (atomic, assign) NSUInteger nextIdentifier;
@property (atomic, strong) NSMutableArray * animationBlocks;
@property (atomic, strong) NSMutableDictionary * identifiers;

@end

@implementation _AnimationHelper

+ (_AnimationHelper *)defaultHelper
{
	static _AnimationHelper * helper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		helper = [[_AnimationHelper alloc] init];
		helper.slowdownFactor = 1.;
	});
	return helper;
}

- (instancetype)init
{
	if ((self = [super init])) {
		self.link = [[UIScreen mainScreen] displayLinkWithTarget:self
													selector:@selector(updateScreen:)];
		[self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		self.link.paused = YES;
		
		self.animationBlocks = [[NSMutableArray alloc] initWithCapacity:10];
		self.identifiers = [[NSMutableDictionary alloc] initWithCapacity:10];
		self.nextIdentifier = 1; // Keep identifier 0 for error
	}
	return self;
}

- (const _AnimationBlock *)addAnimationWithUpdateBlock:(_AnimationBlockUpdateHandler)updateHandler
											  duration:(NSTimeInterval)duration
											completion:(_AnimationBlockCompletionHandler)completion
											   repeats:(BOOL)repeats
{
	return [self addAnimationWithUpdateBlock:updateHandler duration:duration completion:completion repeats:repeats identifier:0];
}

- (const _AnimationBlock *)addAnimationWithUpdateBlock:(_AnimationBlockUpdateHandler)updateHandler
											  duration:(NSTimeInterval)duration
											completion:(_AnimationBlockCompletionHandler)completion
											   repeats:(BOOL)repeats
											identifier:(NSUInteger)identifier
{
	NSUInteger newIdentifier = identifier;
	if (identifier == 0) {
		while (self.identifiers[@(self.nextIdentifier++)]) { } // Find a free to use ID
		newIdentifier = self.nextIdentifier;
	}
	
	_AnimationBlock * block = [[_AnimationBlock alloc] initWithIdentifier:newIdentifier];
	block.updateBlock = updateHandler;
	block.duration = duration;
	block.completionBlock = completion;
	block.progression = 0.;
	block.repeats = repeats;
	@synchronized(self.animationBlocks) {
		[self.animationBlocks addObject:block]; }
	
	if (self.animationBlocks.count > 0)
		[self startUpdating];
	
	@synchronized(self.identifiers) {
		self.identifiers[@(newIdentifier)] = block; }
	
	return block;
}

- (void)updateScreen:(CADisplayLink *)sender
{
	static dispatch_queue_t queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queue = dispatch_queue_create("com.lisacintosh.elsas-gone.update-screen", DISPATCH_QUEUE_CONCURRENT); });
	
	for (_AnimationBlock * block in self.animationBlocks.copy) {
		
		dispatch_async(queue, ^{
			
			if (block.isCancelled) {
				dispatch_async(queue, ^{
					@synchronized(self.animationBlocks) {
						[self.animationBlocks removeObjectIdenticalTo:block]; }
					@synchronized(self.identifiers) {
						[self.identifiers removeObjectForKey:@(block.identifier)]; }
				});
				
			} else {
				block.progression += self.link.duration / (block.duration * _slowdownFactor);
				
				if (block.updateBlock)
					dispatch_async(dispatch_get_main_queue(), ^{ block.updateBlock(MIN(block.progression, 1.)); });
				//dispatch_async(queue, ^{ block.updateBlock(MIN(block.progression, 1.)); });
				
				if (block.progression >= 1.) {
					if (block.completionBlock)
						dispatch_async(dispatch_get_main_queue(), ^{ block.completionBlock(); });
					//dispatch_async(queue, ^{ block.completionBlock(); });
					
					if (block.repeats) {
						block.progression = 0.;
					} else {
						dispatch_async(queue, ^{
							@synchronized(self.animationBlocks) {
								[self.animationBlocks removeObjectIdenticalTo:block]; }
							@synchronized(self.identifiers) {
								[self.identifiers removeObjectForKey:@(block.identifier)]; }
						});
						
						/*
						 dispatch_async(dispatch_get_main_queue(), ^{
						 [self.animationBlocks removeObjectIdenticalTo:block];
						 [self.identifiers removeObjectForKey:@(block.identifier)];
						 });
						 */
					}
					
				}
			}
		});
	}
	
	if (self.animationBlocks.count == 0)
		[self stopUpdating];
}

- (void)startUpdating
{
	self.link.paused = NO;
}

- (void)stopUpdating
{
	self.link.paused = YES;
}

- (_AnimationBlock *)animationBlockWithIdentifier:(NSUInteger)identifier
{
	return self.identifiers[@(identifier)];
}

- (void)cancelAnimationBlock:(_AnimationBlock *)block
{
	[block cancel];
}

- (BOOL)cancelAnimationBlockWithIdentifier:(NSUInteger)identifier
{
	_AnimationBlock * block = [self animationBlockWithIdentifier:identifier];
	[self cancelAnimationBlock:block];
	return (block != nil);
}

@end


@implementation NSObject (addition)

+ (float)setSlowdownFactor:(float)factor
{
	float oldFactor = [_AnimationHelper defaultHelper].slowdownFactor;
	if (factor <= 0.) return oldFactor;
	
	[_AnimationHelper defaultHelper].slowdownFactor = factor;
	return oldFactor;
}

+ (BOOL)cancelAnimationWithIdentifier:(NSUInteger)identifier
{
	return [[_AnimationHelper defaultHelper] cancelAnimationBlockWithIdentifier:identifier];
}

+ (NSUInteger)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(float progression))block
{
	return [self animateWithDuration:duration animations:block completion:NULL];
}

+ (NSUInteger)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(float progression))block completion:(void(^)(void))completion
{
	if (duration <= 0.) {
		if (completion) completion();
		return 0;
	}
	const _AnimationBlock * animationBlock = [[_AnimationHelper defaultHelper] addAnimationWithUpdateBlock:block duration:duration completion:completion repeats:NO];
	return animationBlock.identifier;
}

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration
{
	[self animationBlock:block duration:duration completion:NULL];
}

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
	[self animateWithDuration:duration animations:block completion:completion];
}

+ (BOOL)cancelPerformBlockWithIdentifier:(NSUInteger)identifier
{
	return [[_AnimationHelper defaultHelper] cancelAnimationBlockWithIdentifier:identifier];
}


+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
	return [self performBlock:block afterDelay:delay repeats:NO identifier:0];
}

+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay repeats:(BOOL)repeats
{
	return [self performBlock:block afterDelay:delay repeats:repeats identifier:0];
}

+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay identifier:(NSUInteger)identifier
{
	return [self performBlock:block afterDelay:delay repeats:NO identifier:identifier];
}

+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay repeats:(BOOL)repeats identifier:(NSUInteger)identifier
{
	const _AnimationBlock * animationBlock = [[_AnimationHelper defaultHelper] addAnimationWithUpdateBlock:NULL
																								  duration:delay
																								completion:block
																								   repeats:repeats
																								identifier:identifier];
	return animationBlock.identifier;
}

@end
