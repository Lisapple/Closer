//
//  UserDataManager.h
//  Closer
//
//  Created by Max on 01/05/2017.
//
//

@import Foundation;
@import CoreData;

@interface UserDataManager : NSObject

+ (instancetype)defaultManager;

- (BOOL)synchronize;

@end
