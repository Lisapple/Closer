//
//  PageView.h
//  Closer
//
//  Created by Maxime Leroy on 6/20/13.
//
//

#import <UIKit/UIKit.h>

@class PageView;
@protocol PageViewDelegate

@optional

- (void)viewDidSingleTap:(PageView *)page;
- (void)viewDidDoubleTap:(PageView *)page;

- (void)pageViewWillShowSettings:(PageView *)page;

@end

/*** @abstract: abstract method used for CountdownPageView and TimerPageView ***/
@interface PageView : UIView
{
@public
	
	Countdown * countdown;
	
	CGPoint position;
	
	NSObject <PageViewDelegate> * delegate;
	
	UIInterfaceOrientation orientation;
}

@property (nonatomic, strong) Countdown * countdown;

@property (nonatomic, assign) CGPoint position;

@property (nonatomic, strong) NSObject <PageViewDelegate> * delegate;

@property (nonatomic, assign) UIInterfaceOrientation orientation;

- (void)update;

#pragma Page Resources Management

- (void)load;
- (void)unload;

@end
