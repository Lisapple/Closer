//
//  Constants.h
//  Closer
//
//  Created by Max on 23/03/2017.
//
//

#ifndef Constants_h
#define Constants_h

#if TARGET_IPHONE_SIMULATOR
#  define NSDebugLog(format, ...)  NSLog(@"[DEBUG] " format, ##__VA_ARGS__)
#else
#  define NSDebugLog(format, ...)
#endif

#define CLIP(A, X, B) ( MAX(A, MIN(X, B)) )
#define LERP(A, X, B) ( A + X*(B-A) )

#define DISTANCE(P1, P2) (sqrt((P1.x-P2.x)*(P1.x-P2.x)+(P1.y-P2.y)*(P1.y-P2.y)))

#define kDefaultEventDuration 7200 // The default duration in seconds for EKEvent and VEvent

#define TARGET_IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if !defined(OrderComparisonResult)
#  define OrderComparisonResult(A, B) ( ((A) < (B))? NSOrderedAscending : (((A) > (B))? NSOrderedDescending : NSOrderedSame) )
#endif

#define kLastSelectedCountdownIdentifierKey	@"lastSelectedCountdownIdentifier"

#define DynamicThemesEnabledKey @"dynamic-themes-enabled"

#endif /* Constants_h */
