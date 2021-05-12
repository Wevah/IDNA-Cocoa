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
			return -1;
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

+ (NSError *)errorWithCode:(UTS46Error)code {
	return [NSError errorWithDomain:UTS46ErrorDomain code:code userInfo:nil];
}

+ (UTS46Header *)parseHeaderFromData:(NSData *)data error:(NSError **)error {
	if (data.length < 12) {
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
		*error = [self errorWithCode:UTS46ErrorUnknownVersion];
		return NO;
	}

	NSUInteger offset = header.dataOffset;

	if (fileData.length <= offset) {
		*error = [self errorWithCode:UTS46ErrorBadSize];
	}

	NSData *compressedData = [fileData subdataWithRange:(NSRange){ offset, fileData.length - offset}];

	if (compressedData.CRC32 != header.CRC) {
		*error = [self errorWithCode:UTS46ErrorBadCRC];
		return nil;
	}

	NSData *data = [self decompressData:compressedData algorithm:header.compression];

	if (!data) {
		*error = [self errorWithCode:UTS46ErrorDecompression];
		return nil;
	}

}

+ (NSBundle *)bundle {
#ifdef SWIFT_PACKAGE
	return SWIFTPM_MODULE_BUNDLE;
#else
	return [NSBundle bundleForClass:self]
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
	uint8_t *destinationBuffer = malloc(capacity);

	size_t decodedCount = compression_decode_buffer(destinationBuffer, capacity, data.bytes, data.length, NULL, rawAlgorithm);

	if (decodedCount == 0 || decodedCount == capacity) {
		return nil;
	}

	return [NSData dataWithBytes:destinationBuffer length:decodedCount];
}

#if __LITTLE_ENDIAN__
static const NSStringEncoding UTF32_ENCODING = NSUTF32LittleEndianStringEncoding;
#elif __BIG_ENDIAN__
static const NSStringEncoding UTF32_ENCODING = NSUTF32BigEndianStringEncoding;
#else
#error "Unsupported endianness"
#endif

+ (NSUInteger)parseCharacterMapFromData:(NSData *)data start:(NSUInteger)start {
	NSMutableDictionary<NSNumber *, NSString *> *dict = [NSMutableDictionary dictionary];

	NSUInteger index = start;
	NSUInteger count = data.length;

	while (index < count) {
		BOOL markerFound = NO;
		NSMutableData *accumulator = [NSMutableData data];
		uint8_t *bytes = (uint8_t)data.bytes;

		while (bytes[index] != UTS46MarkerSequenceTerminator) {
			if (bytes[index] > UTS46MarkerMin) {
				markerFound = YES;
				break;
			}

			[accumulator appendBytes:bytes[index] length:1];
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

+ (NSRange)parseRangesFromString:(NSString *)string {
	NSData *utf32 = [string dataUsingEncoding:UTF32_ENCODING];
	
	if (utf32.length % 8 != 0) {
		return (NSRange){ NSNotFound, 0 };
	}


}

@end
