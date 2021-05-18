//
//   NSString+IDNA.m
//  
//
//  Created by Nate Weaver on 2021-05-18.
//

#import "NSString+IDNA.h"
#import "UTS46.h"

@interface NSString (IDNAPrivate)

- (nullable NSString *)mapUTS46AndReturnError:(NSError **)error;

@end


@implementation NSString (IDNA)

- (nullable NSString *)IDNAEncoded {
	NSString *mapped = [self mapUTS46AndReturnError:nil];

	if (!mapped) {
		return nil;
	}


}

@end

NSErrorDomain const UTS46MapError;

typedef NS_ENUM(NSInteger, UTS46MapErrorCode) {
	UTS46MapErrorDisallowedCodepoint
};

NSErrorUserInfoKey const UTS46DisallowedCodepointKey;

@implementation NSString (IDNAPrivate)

- (void)getFirstCodePoint:(unichar * _Nonnull)codepoint length:(NSUInteger *)length {
	unichar *first = NULL;
	[self getCharacters:first range:(NSRange){ 0, 1 }];
	*length = 1;

	if (!first) {
		*length = 0;
		return;
	}

	if (UCIsSurrogateHighCharacter(*first)) {
		if (self.length <= 2) {
			codepoint = NULL;
			*length = 0;
		}

		[self getCharacters:first range:(NSRange){ 0, 2 }];
		*length = 2;
	}

	*codepoint = *first;
}

- (nullable NSString *)mapUTS46AndReturnError:(NSError **)error {
	if (![UTS46 loadIfNecessaryAndReturnError:error])
		return nil;

	NSMutableString *result = [NSMutableString string];

	// FIXME: Use the macro from UTS46
	NSData *utf32 = [self dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
	NSUInteger length = utf32.length / 4;
	uint32_t *codepoints = (uint32_t *)utf32.bytes;

	for (NSUInteger i = 0; i < length; ++i) {
		uint32_t codepoint = codepoints[i];

		if ([UTS46.disallowedCharacgers longCharacterIsMember:codepoint]) {
			if (error)
				*error = [NSError errorWithDomain:UTS46MapError code:UTS46MapErrorDisallowedCodepoint userInfo:@{UTS46DisallowedCodepointKey: @(codepoint)}];
			return nil;
		}

		if ([UTS46.ignoredCharacters longCharacterIsMember:codepoint]) {
			continue;
		}

		NSString *mapped = UTS46.characterMap[@(codepoint)];

		if (mapped) {
			[result appendString:mapped];
		} else {
			[result appendString:[[NSString alloc] initWithBytes:&codepoint length:4 encoding:NSUTF32LittleEndianStringEncoding]];
		}
	}

	return [result copy];
}

- (BOOL)isValidLabel {
	if (self.precomposedStringWithCanonicalMapping != self) {
		[NSException raise:NSInternalInconsistencyException format:@"Couldn't load UTS46 data file"];
	}

	if (![self mapUTS46AndReturnError:nil]) {
		return false;
	}

	if (self.length == 0) {
		return false;
	}

	unichar *first = NULL;
	[self getCharacters:first range:(NSRange){ 0, 1 }];
	UniCharCount charlen = 1;

	if (UCIsSurrogateHighCharacter(*first)) {
		if (self.length <= 2) {
			return false;
		}

		[self getCharacters:first range:(NSRange){ 0, 2 }];
		charlen = 2;
	}

	UCCharPropertyValue value;
	UCGetCharProperty(first, charlen, kUCCharPropTypeGenlCategory, &value);

	if (value == kUCGenlCatMarkNonSpacing || value == kUCGenlCatMarkSpacingCombining || value == kUCGenlCatMarkEnclosing) {
		return false;
	}

	return [self hasValidJoiners];
}

- (BOOL)hasValidJoiners {
	if (![UTS46 loadIfNecessaryAndReturnError:nil]) {
		[NSException raise:NSInternalInconsistencyException format:@"Couldn't load UTS46 data file"];
	}


}

@end
