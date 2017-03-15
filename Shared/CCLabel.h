//
//  CCLabel.h
//  Closer
//
//  Created by Maxime on 7/30/14.
//
//

@interface CCLabel : UILabel <NSCopying>

@property (nonatomic, strong) NSString * animatedText;

- (void)setText:(NSString *)text animated:(BOOL)animated;

@end
