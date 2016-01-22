//
//  NSString+addition.h
//  Closer
//
//  Created by Max on 21/01/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (addition)

- (BOOL)matchesWithPattern:(nonnull NSString *)pattern;
- (BOOL)matchesWithPattern:(nonnull NSString *)pattern firstMatch:(NSString * _Nullable * _Nullable)pValue;

@end
