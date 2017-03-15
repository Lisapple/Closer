//
//  PageViewContainer.m
//  Closer
//
//  Created by Max on 05/01/2017.
//
//

#import "PageViewContainer.h"

#import "Countdown+addition.h"

@interface PageViewContainer ()

@property (nonatomic, strong) IBOutlet UIView * contentView;

@end

@implementation PageViewContainer

- (instancetype)initWithPageView:(PageView *)pageView
{
	if ((self = [super initWithFrame:CGRectZero])) {
		self.clipsToBounds = YES;
		_pageView = pageView;
		
		UINib * nib = [UINib nibWithNibName:@"PageViewContainer" bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		_contentView.frame = self.bounds;
		_contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self addSubview:_contentView];
		
		const CGFloat margin = 20;
		pageView.translatesAutoresizingMaskIntoConstraints = NO;
		[_contentView insertSubview:_pageView atIndex:0];
		[_contentView addConstraints:@[ [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
																		toItem:_pageView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
										[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
																		toItem:_pageView attribute:NSLayoutAttributeLeft multiplier:1 constant:-margin],
										[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
																		toItem:_pageView attribute:NSLayoutAttributeRight multiplier:1 constant:margin],
										[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																		toItem:_pageView attribute:NSLayoutAttributeBottom multiplier:1 constant:0] ]];
		
		[self updateUI];
		[self update];
	}
	return self;
}

- (IBAction)showSettings:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(containerWillShowSettings:)])
		[self.delegate containerWillShowSettings:self];
}

- (IBAction)leftAction:(id)sender
{
	if (_pageView.countdown.isPaused) { // Reset
		if ([self.delegate respondsToSelector:@selector(containerWillResetTimer:)])
			[self.delegate containerWillResetTimer:self];
	} else { // Resume
		if ([self.delegate respondsToSelector:@selector(containerWillResumeTimer:)])
			[self.delegate containerWillResumeTimer:self];
	}
}

- (void)updateLeftButton
{
	_leftButton.hidden = (_pageView.countdown.type != CountdownTypeTimer);
	
	if (_pageView.countdown.type == CountdownTypeTimer) {
		NSString * name = (_pageView.countdown.isPaused) ? @"reset" : @"pause";
		[_leftButton setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
		_leftButton.enabled = (_pageView.countdown.durations.count > 0);
	}
}

- (void)updateUI
{
	_contentView.backgroundColor = [UIColor backgroundColorForStyle:_pageView.countdown.style];
	
	UIColor * textColor = [UIColor textColorForStyle:_pageView.countdown.style];
	_nameLabel.attributedText = _pageView.countdown.attributedName;
	
	[self updateLeftButton];
	_leftButton.tintColor = textColor;
	_infoButton.tintColor = textColor;
}

- (void)update
{
	[self updateUI];
	[_pageView update];
}

@end
