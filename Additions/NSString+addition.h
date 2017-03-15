//
//  NSString+addition.h
//  Closer
//
//  Created by Max on 21/01/16.
//
//

@interface NSString (addition)

- (BOOL)isMatchingWithPattern:(nonnull NSString *)pattern;
- (BOOL)isMatchingWithPattern:(nonnull NSString *)pattern firstMatch:(NSString * _Nullable * _Nullable)pValue;

@end
