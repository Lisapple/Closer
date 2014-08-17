//
//  NSArray+addition.h
//  Closer
//
//  Created by Maxime Leroy on 8/12/13.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (addition)

- (NSString *)componentsJoinedByString:(NSString *)separator andLastString:(NSString *)endSeparator DEPRECATED_ATTRIBUTE;
- (NSString *)componentsJoinedByString:(NSString *)separator withLastJoin:(NSString *)endJoin;

@end
