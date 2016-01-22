//
//  PageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import <UIKit/UIKit.h>

@interface _DeleteButton : UIButton

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

/*** @abstract: abstract method used for CountdownPageView and TimerPageView ***/
@interface PageView : UIView <UIScrollViewDelegate>

@property (nonatomic, assign) BOOL showDeleteConfirmation, isViewShown;
@property (nonatomic, strong) Countdown * countdown;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, weak) NSObject <PageViewDelegate> * delegate;

@property (nonatomic, assign) CountdownStyle style;

@property (nonatomic, strong) IBOutlet UIButton * infoButton;

- (void)update;
- (void)hideDeleteConfirmation; // Always with an animation
- (void)hideDeleteConfirmationWithAnimation:(BOOL)animated;

// Subclasses must call these method with super
- (void)viewWillShow:(BOOL)animated;
- (void)viewDidHide:(BOOL)animated;

@end
