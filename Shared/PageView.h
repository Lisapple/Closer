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

static const NSTimeInterval kDoubleTapDelay = 0.35;

/**
 @abstract: abstract method used for CountdownPageView and TimerPageView
 */
@interface PageView : UIView

@property (nonatomic, assign) BOOL isViewShown;
@property (nonatomic, strong) Countdown * countdown;
@property (nonatomic, assign) CGPoint position; // ???: USED?
@property (nonatomic, weak) NSObject <PageViewDelegate> * delegate;

@property (nonatomic, assign) CountdownStyle style; // ??? Must be set only by countdown?

//@property (nonatomic, strong) IBOutlet UIButton * infoButton;

- (void)update;

// Subclasses must call these method with super
- (void)viewWillShow:(BOOL)animated;
- (void)viewDidHide:(BOOL)animated;

- (NSTimeInterval)minDurationBeforeIdle;

@end
