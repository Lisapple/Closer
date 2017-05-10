//
//  PageViewContainer.h
//  Closer
//
//  Created by Max on 05/01/2017.
//
//

#import "PageView.h"

@class PageViewContainer;
@protocol PageViewContainerDelegate

@optional
- (void)containerWillShowSettings:(PageViewContainer *)container;
- (void)containerWillResetTimer:(PageViewContainer *)container;
- (void)containerWillResumeTimer:(PageViewContainer *)container;

@end

/**
 @abstract: abstract method used for CountdownPageView and TimerPageView on iPad
 */
@interface PageViewContainer : UIView

@property (nonatomic, strong, readonly) PageView * pageView;
@property (nonatomic, weak) NSObject <PageViewContainerDelegate> * delegate;

@property (nonatomic, strong) IBOutlet UIButton * leftButton;
@property (nonatomic, strong) IBOutlet UILabel * nameLabel;
@property (nonatomic, strong) IBOutlet UIButton * infoButton;

- (instancetype)initWithPageView:(PageView *)pageView;
- (void)update;

@end
