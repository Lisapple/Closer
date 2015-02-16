//
//  PageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import <UIKit/UIKit.h>

@interface _DeleteButton : UIButton
{
	UILabel * _titleLabel;
}

@end


@class PageView;
@protocol PageViewDelegate

@optional

//- (void)pageViewDidSingleTap:(PageView *)page;
//- (void)pageViewDidDoubleTap:(PageView *)page;

- (void)pageViewWillShowSettings:(PageView *)page;

- (void)pageViewDidScroll:(PageView *)page offset:(CGPoint)offset;

- (BOOL)pageViewShouldShowDeleteConfirmation:(PageView *)page;
- (void)pageViewWillShowDeleteConfirmation:(PageView *)page;
- (void)pageViewDidShowDeleteConfirmation:(PageView *)page;
- (void)pageViewDidHideDeleteConfirmation:(PageView *)page;

- (BOOL)pageViewShouldBeDeleted:(PageView *)page;
- (void)pageViewDeleteButtonDidTap:(PageView *)page;

@end

static const NSTimeInterval kDoubleTapDelay = 0.35;

typedef NS_OPTIONS(NSUInteger, PageViewStyle) {
	PageViewStyleNight = 0, // Default
	PageViewStyleDay,
	PageViewStyleDawn,
	PageViewStyleOasis,
	PageViewStyleSpring,
};

/*** @abstract: abstract method used for CountdownPageView and TimerPageView ***/
@interface PageView : UIView <UIScrollViewDelegate>
{
	UIButton * _deleteButton;
	
	Countdown * countdown;
	CGPoint position;
	
	CGPoint _startLocation, _offset;
	BOOL _shouldShowDeleteConfirmation;
}

@property (nonatomic, assign) BOOL showDeleteConfirmation;
@property (nonatomic, strong) Countdown * countdown;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, weak) NSObject <PageViewDelegate> * delegate;

@property (nonatomic, strong) UIScrollView * scrollView; // @FIXME: Private?

@property (nonatomic, assign) PageViewStyle style;

@property (nonatomic, strong) IBOutlet UIButton * infoButton;

- (void)update;
- (void)hideDeleteConfirmation; // Always with an animation
- (void)hideDeleteConfirmationWithAnimation:(BOOL)animated;

@end
