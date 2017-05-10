//
//  Utilities.h
//  Closer
//
//  Created by Max on 20/12/2016.
//
//

#ifndef Utilities_h
#define Utilities_h

#define IS_IOS10_OR_MORE ( [UIDevice currentDevice].systemVersion.floatValue >= 10 )

#define IGNORE_DEPRECATION_BEGIN _Pragma("clang diagnostic begin") _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
#define IGNORE_DEPRECATION_END   _Pragma("clang diagnostic end")

#endif /* Utilities_h */
