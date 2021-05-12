//
//  UTS46.h
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

#import <Foundation/Foundation.h>
#import <compression.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, UTS46JoiningType) {
	UTS46JoiningTypeCausing	= 'C',
	UTS46JoiningTypeDual = 'D',
	UTS46JoiningTypeRight = 'R',
	UTS46JoiningTypeLeft = 'L',
	UTS46JoiningTypeTransparent = 'T'
};

typedef NS_ENUM(uint8_t, UTS46Marker) {
	UTS46MarkerCharacterMap = UINT8_MAX,
	UTS46MarkerIgnoredCharacters = UINT8_MAX - 1,
	UTS46MarkerDisallowedCharacters = UINT8_MAX - 2,
	UTS46MarkerJoiningTypes = UINT8_MAX - 3,

	UTS46MarkerMin = UINT8_MAX - 10, // No valid UTF-8 byte can fall here.

	UTS46MakerkerSequenceTerminator = 0
};

/// Identical values to `NSData.CompressionAlgorithm + 1`.
typedef NS_ENUM(uint8_t, UTS46CompressionAlgorithm) {
	UTS46CompressionAlgorithmNone,
	UTS46CompressionAlgorithmLZFSE,
	UTS46CompressionAlgorithmLZ4,
	UTS46CompressionAlgorithmLZMA,
	UTS46CompressionAlgorithmZLIB
};

compression_algorithm UTS46RawAlgorithm(UTS46CompressionAlgorithm algo) {
	switch (algo) {
		case UTS46CompressionAlgorithmLZFSE:
			return COMPRESSION_LZFSE;
		case UTS46CompressionAlgorithmLZ4:
			return COMPRESSION_LZ4;
		case UTS46CompressionAlgorithmLZMA:
			return COMPRESSION_LZMA;
		case UTS46CompressionAlgorithmZLIB:
			return COMPRESSION_ZLIB;
		default:
			return -1;
	}
}

static CFDictionaryRef characterMap; // uint32_t -> CFString
static NSCharacterSet *ignoredCharacters;
static NSCharacterSet *disallowedCharacters;
static CFDictionaryRef joiningTypes; // uint32_t -> CFString

static BOOL isLoaded;

@interface UTS46: NSObject


@end

NS_ASSUME_NONNULL_END
