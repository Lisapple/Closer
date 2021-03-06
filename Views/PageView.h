//
//  PageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

@class PageView;
@protocol PageViewDelegate

@optional
- (void)pageViewDidDoubleTap:(PageView *)page;

@end

/**
 @abstract: abstract method used for CountdownPageView and TimerPageView
 */
@interface PageView : UIView

@property (nonatomic, weak) NSObject <PageViewDelegate> * delegate;

@property (nonatomic, strong) Countdown * countdown;

@property (nonatomic, readonly, assign, getter=isVisible) BOOL visible;
@property (nonatomic, readonly) NSTimeInterval minDurationBeforeIdle;

- (void)update;

- (void)setNeedsUpdateStyle;
- (void)styleDidChange:(CountdownStyle)style;

// Subclasses must call these method with super
- (void)viewWillShow:(BOOL)animated;
- (void)viewDidHide:(BOOL)animated;


@end
