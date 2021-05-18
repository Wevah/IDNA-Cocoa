//
//  UTS46.h
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface UTS46: NSObject

+ (BOOL)loadIfNecessaryAndReturnError:(NSError **)error;

@property (class, nonatomic, readonly)	NSCharacterSet	*disallowedCharacgers;
@property (class, nonatomic, readonly) NSCharacterSet	*ignoredCharacters;
@property (class, nonatomic, readonly)	NSDictionary<NSNumber *, NSString *>	*characterMap;


@end

NS_ASSUME_NONNULL_END
