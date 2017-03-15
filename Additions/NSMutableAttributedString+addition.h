//
//  NSMutableAttributedString+addition.h
//  Closer
//
//  Created by Max on 16/01/2017.
//
//

@import Foundation;

@interface NSMutableAttributedString (addition)

- (void)appendAttributes:(nullable NSDictionary<NSString *, id> *)attrs format:(nonnull NSString *)string, ... NS_FORMAT_FUNCTION(2,3);

- (void)appendString:(nonnull NSString *)string attributes:(nullable NSDictionary<NSString *, id> *)attrs;

@end
