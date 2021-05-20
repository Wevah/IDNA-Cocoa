//
//  UTS46.h
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

#if __LITTLE_ENDIAN__
static const NSStringEncoding UTF32_ENCODING = NSUTF32LittleEndianStringEncoding;
#elif __BIG_ENDIAN__
static const NSStringEncoding UTF32_ENCODING = NSUTF32BigEndianStringEncoding;
#else
#error "Unsupported endianness"
#endif

typedef NS_ENUM(uint8_t, UTS46JoiningType) {
	UTS46JoiningTypeCausing	= 'C',
	UTS46JoiningTypeDual = 'D',
	UTS46JoiningTypeRight = 'R',
	UTS46JoiningTypeLeft = 'L',
	UTS46JoiningTypeTransparent = 'T'
};

@interface UTS46: NSObject

+ (BOOL)loadIfNecessaryAndReturnError:(NSError **)error;

@property (class, nonatomic, readonly) NSDictionary<NSNumber *, NSString *>	*characterMap;
@property (class, nonatomic, readonly) NSCharacterSet	*disallowedCharacters;
@property (class, nonatomic, readonly) NSCharacterSet	*ignoredCharacters;
@property (class, nonatomic, readonly) NSDictionary<NSNumber *, NSNumber *> *joiningTypes; // uint32_t -> UTS46JoiningType


@end

NS_ASSUME_NONNULL_END
