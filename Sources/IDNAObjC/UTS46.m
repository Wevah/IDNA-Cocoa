//
//  UTS46.m
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

#import "UTS46.h"
#import <compression.h>
#import "NSData+Extensions.h"
#import <os/log.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, UTS46Marker) {
	UTS46MarkerCharacterMap = UINT8_MAX,
	UTS46MarkerIgnoredCharacters = UINT8_MAX - 1,
	UTS46MarkerDisallowedCharacters = UINT8_MAX - 2,
	UTS46MarkerJoiningTypes = UINT8_MAX - 3,

	UTS46MarkerMin = UINT8_MAX - 10, // No valid UTF-8 byte can fall here.

	UTS46MarkerSequenceTerminator = 0
};

static NSErrorDomain const UTS46ErrorDomain = @"UTS46ErrorDomain";

typedef NS_ENUM(NSInteger, UTS46Error) {
	UTS46ErrorBadSize,
	UTS46ErrorDecompression,
	UTS46ErrorCompression,
	UTS46ErrorBadMarker,
	UTS46ErrorUnknownVersion,
	UTS46ErrorBadCRC
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
			return 0;
	}
}

@interface UTS46Header: NSObject

@property (readonly) NSData *rawData;

@property (readonly) uint8_t version;
@property (readonly) BOOL hasCRC;
@property (readonly) uint32_t CRC;
@property (nonatomic, readonly) UTS46CompressionAlgorithm compression;
@property (nonatomic, readonly) NSUInteger dataOffset;

- (instancetype)initWithData:(NSData *)data;

@end

static char * const signature = "UTS#46";

NS_ENUM(uint8_t, UTS46HeaderFlagsMask) {
	UTS46HeaderFlagsMaskHasCRC = 1 << 3,
	UTS46HeaderFlagsMaskCompression = 0x7
};

@implementation UTS46Header {
	uint8_t _flags;
}

- (instancetype)initWithData:(NSData *)data {
	if (data.length < 8)
		return nil;

	if (memcmp(data.bytes, signature, strlen(signature)) != 0)
		return nil;

	self = [super init];

	[data getBytes:&_version range:(NSRange){ 6, 1 }];
	[data getBytes:&_flags range:(NSRange){ 7, 1 }];

	if ((_flags & UTS46HeaderFlagsMaskHasCRC) != 0) {
		if (data.length < 12) {
			return nil;
		}

		uint32_t littleCRC;
		[data getBytes:&littleCRC range:(NSRange){ 8, 4 }];
		_CRC = CFSwapInt32LittleToHost(littleCRC);
	}

	return self;
}

- (instancetype)initWithCompressionAlgorithm:(UTS46CompressionAlgorithm)compression crc:(uint32_t)crc {
	self = [super init];

	if (self) {
		_version = 1;
		_flags = (crc != 0 ? UTS46HeaderFlagsMaskHasCRC : 0) | compression;
	}

	return self;
}

- (BOOL)hasCRC {
	return (_flags & UTS46HeaderFlagsMaskHasCRC) != 0;
}

- (UTS46CompressionAlgorithm)compression {
	return _flags & UTS46HeaderFlagsMaskCompression;
}

- (NSUInteger)dataOffset {
	return 8 + (self.hasCRC ? 4 : 0);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"has CRC: %@; compression: %u", self.hasCRC ? @"yes" : @"no", self.compression];
}

@end

static NSDictionary<NSNumber *, NSString *> *characterMap; // uint32_t -> NSString
static NSCharacterSet *ignoredCharacters;
static NSCharacterSet *disallowedCharacters;
static NSDictionary<NSNumber *, NSNumber *> *joiningTypes; // uint32_t -> char

static BOOL isLoaded;

// MARK: - Loading

@implementation UTS46

+ (NSDictionary<NSNumber *, NSString *> *)characterMap {
	return characterMap;
}

+ (NSCharacterSet *)ignoredCharacters {
	return ignoredCharacters;
}

+ (NSCharacterSet *)disallowedCharacters {
	return disallowedCharacters;
}

+ (NSDictionary<NSNumber *, NSNumber *> *)joiningTypes {
	return joiningTypes;
}

+ (NSError *)errorWithCode:(UTS46Error)code {
	return [NSError errorWithDomain:UTS46ErrorDomain code:code userInfo:nil];
}

+ (nullable UTS46Header *)parseHeaderFromData:(NSData *)data error:(NSError **)error {
	if (data.length < 12) {
		if (error)
			*error = [self errorWithCode:UTS46ErrorBadSize];
		return nil;
	}

	return [[UTS46Header alloc] initWithData:data];
}

+ (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error {
	NSData *fileData = [NSData dataWithContentsOfURL:url options:0 error:error];

	if (!fileData) { return nil; }

	UTS46Header *header = [self parseHeaderFromData:fileData error:error];

	if (!header) { return nil; }

	if (header.version != 1) {
		if (error)
			*error = [self errorWithCode:UTS46ErrorUnknownVersion];
		return NO;
	}

	NSUInteger offset = header.dataOffset;

	if (fileData.length <= offset) {
		if (error)
			*error = [self errorWithCode:UTS46ErrorBadSize];
	}

	NSData *compressedData = [fileData subdataWithRange:(NSRange){ offset, fileData.length - offset}];

	if (compressedData.CRC32 != header.CRC) {
		if (error)
			*error = [self errorWithCode:UTS46ErrorBadCRC];
		return NO;
	}

	NSData *data = [self decompressData:compressedData algorithm:header.compression];

	if (!data) {
		if (error)
			*error = [self errorWithCode:UTS46ErrorDecompression];
		return NO;
	}


	return YES;
}

+ (NSBundle *)bundle {
#ifdef SWIFT_PACKAGE
	return SWIFTPM_MODULE_BUNDLE;
#else
	return [NSBundle bundleForClass:self];
#endif
}

+ (BOOL)loadIfNecessaryAndReturnError:(NSError **)error {
	if (isLoaded) {
		return YES;
	}

	NSURL *url = [[self bundle] URLForResource:@"uts46" withExtension:nil];

	if (!url) {
		if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
			os_log_error(OS_LOG_DEFAULT, "uts46 data file is missing!");
		} else {
			NSLog(@"uts46 data file is missing!");
		}

		if (error)
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
		return NO;
	}

	return [self loadFromURL:url error:error];
}

+ (nullable NSData *)decompressData:(NSData *)data algorithm:(UTS46CompressionAlgorithm)algorithm {
	if (algorithm == UTS46CompressionAlgorithmNone) {
		return data;
	}

	compression_algorithm rawAlgorithm = UTS46RawAlgorithm(algorithm);

	NSUInteger capacity = 131072; // 128 KB
	NSMutableData *dest = [NSMutableData data];
	dest.length = capacity;

	size_t decodedCount = compression_decode_buffer(dest.mutableBytes, capacity, data.bytes, data.length, NULL, rawAlgorithm);

	if (decodedCount == 0 || decodedCount == capacity) {
		return nil;
	}

	dest.length = decodedCount;

	return [dest copy];
}

+ (NSUInteger)parseCharacterMapFromData:(NSData *)data start:(NSUInteger)start {
	NSMutableDictionary<NSNumber *, NSString *> *dict = [NSMutableDictionary dictionary];

	NSUInteger index = start;
	NSUInteger count = data.length;

	while (index < count) {
		BOOL markerFound = NO;
		NSMutableData *accumulator = [NSMutableData data];
		uint8_t *bytes = (uint8_t *)data.bytes;

		while (bytes[index] != UTS46MarkerSequenceTerminator) {
			if (bytes[index] > UTS46MarkerMin) {
				markerFound = YES;
				break;
			}

			[accumulator appendBytes:&bytes[index] length:1];
			++index;
		}

		if (markerFound) { continue; }

		NSString *str = [[NSString alloc] initWithData:accumulator encoding:NSUTF8StringEncoding];

		if (str.length == 0) {
			continue;
		}

		NSData *utf32 = [str dataUsingEncoding:UTF32_ENCODING];

		uint32_t codepoint;
		[utf32 getBytes:&codepoint range:(NSRange){ 0, sizeof(codepoint) }];

		NSString *remainder = [[NSString alloc] initWithData:[utf32 subdataWithRange:(NSRange){ 4, utf32.length - 4}] encoding:UTF32_ENCODING];

		dict[@(codepoint)] = remainder;
	}

	characterMap = [dict copy];
	return index;
}

+ (nullable NSArray<NSValue *> *)parseRangesFromString:(NSString *)string {
	NSData *utf32 = [string dataUsingEncoding:UTF32_ENCODING];

	if (utf32.length % 8 != 0) {
		return nil;
	}

	uint32_t *castBytes = (uint32_t *)utf32.bytes;

	NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
	NSUInteger first = 0;

	for (NSUInteger i = 0; i < utf32.length / 4; ++i) {
		if (i % 2 == 0){
			first = castBytes[i];
		} else if (first != 0) {
			[ranges addObject:[NSValue valueWithRange:(NSRange){ first, castBytes[i] }]];
		}
	}

	return [ranges copy];
}

+ (nullable NSCharacterSet *)parseCharacterSetFromData:(NSData *)data startingAt:(NSUInteger *)index {
	NSMutableData *accumulator = [NSMutableData data];
	NSUInteger i = *index;
	const uint8_t *bytes = [data bytes];

	while (i < data.length && bytes[i] < UTS46MarkerMin) {
		[accumulator appendBytes:&bytes[i] length:1];
		++i;
	}

	NSString *str = [[NSString alloc] initWithData:accumulator encoding:NSUTF8StringEncoding];

	NSArray *ranges = [self parseRangesFromString:str];

	if (!ranges) {
		*index = i;
		return nil;
	}

	NSMutableCharacterSet *charset = [[NSMutableCharacterSet alloc] init];

	for (NSValue *value in ranges) {
		[charset addCharactersInRange:value.rangeValue];
	}

	*index = i;
	return [charset copy];
}

+ (NSUInteger)parseIgnoredCharactersFromData:(NSData *)data startingAt:(NSUInteger)index {
	ignoredCharacters = [self parseCharacterSetFromData:data startingAt:&index];
	return index;
}

+ (NSUInteger)parseDisallowedCharactersFromData:(NSData *)data startingAt:(NSUInteger)index {
	disallowedCharacters = [self parseCharacterSetFromData:data startingAt:&index];
	return index;
}

+ (NSUInteger)parseJoiningTypesFromData:(NSData *)data startingAt:(NSUInteger)index {
	const uint8_t *bytes = [data bytes];

	NSMutableDictionary<NSNumber *, NSNumber *> *dict = [NSMutableDictionary dictionary];

	while (index < data.length && bytes[index] < UTS46MarkerMin) {
		NSMutableData *accumulator = [NSMutableData data];
		BOOL shouldBreak = NO;

		while (index < data.length) {
			if (bytes[index] > UTS46MarkerMin) {
				shouldBreak = YES;
			}

			[accumulator appendBytes:&bytes[index] length:1];
			++index;
		}

		if (shouldBreak)
			break;

		NSString *str = [[NSString alloc] initWithData:accumulator encoding:NSUTF8StringEncoding];
		NSData *utf32 = [str dataUsingEncoding:UTF32_ENCODING];
		uint32_t *castBytes = (uint32_t *)data.bytes;

		UTS46JoiningType type = 0;
		uint32_t first = 0;

		for (NSUInteger i = 0; i < utf32.length / 4; ++i) {
			if (castBytes[i] <= 127) {
				type = (UTS46JoiningType)castBytes[i];
			} else if (type == 0) {
				if (first == 0) {
					first = castBytes[i];
				} else {
					for (uint32_t j = first; j <= castBytes[i]; ++i) {
						dict[@(j)] = @(type);
					}

					first = 0;
				}
			}
		}
	}

	joiningTypes = [dict copy];

	return index;
}

@end

NS_ASSUME_NONNULL_END
