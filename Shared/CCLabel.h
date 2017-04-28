//
//  CCLabel.h
//  Closer
//
//  Created by Maxime on 7/30/14.
//
//

@interface CCLabel : UILabel <NSCopying>

@property (nonatomic, strong, nullable) NSString * animatedText;

/// `animated` is ignored of motion reduction is enabled from accessibility
- (void)setText:(NSString * _Nullable)text animated:(BOOL)animated;

@end
