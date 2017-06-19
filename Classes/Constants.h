//
//  Constants.h
//  Closer
//
//  Created by Max on 23/03/2017.
//
//

#ifndef Constants_h
#define Constants_h

// Deprecated macro

#define IGNORE_DEPRECATION_BEGIN _Pragma("clang diagnostic begin") _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
#define IGNORE_DEPRECATION_END   _Pragma("clang diagnostic end")

// Plateform macros

#define TARGET_IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

// Math helpers

#define CLIP(A, X, B) ( MAX(A, MIN(X, B)) )
#define LERP(A, X, B) ( A + X*(B-A) )

#define DISTANCE(P1, P2) (sqrt(pow(P1.x-P2.x, 2)+pow(P1.y-P2.y, 2)))

#if !defined(OrderComparisonResult)
#  define OrderComparisonResult(A, B) ( ((A) < (B))? NSOrderedAscending : (((A) > (B))? NSOrderedDescending : NSOrderedSame) )
#endif

// Constants

#define kDefaultEventDuration 7200 // The default duration in seconds for EKEvent and VEvent

// Key constants

#define kLastSelectedCountdownIdentifierKey	@"lastSelectedCountdownIdentifier"

#define DynamicThemesEnabledKey @"dynamic-themes-enabled"

#endif /* Constants_h */
