//
//  NSStringPunycodeAdditions.m
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005 Derailer. All rights reserved.
//

#import "NSStringPunycodeAdditions.h"


// Almost all of the straightup C was taken from the Punycode spec, RFC 3492.
// For some other stuff, see RFC 3490 (Internationalizing Domain Names in Applications)

enum {
	base = 36,
	tmin = 1,
	tmax = 26,
	skew = 38,
	damp = 700,
	initial_bias = 72,
	initial_n = 0x80,
	delimiter = '-'
};

/* basic(cp) tests whether cp is a basic code point: */
#define basic(cp) ((unsigned)(cp) < 0x80)

/* delim(cp) tests whether cp is a delimiter: */
#define delim(cp) ((cp) == delimiter)

/* decode_digit(cp) returns the numeric value of a basic code */
/* point (for use in representing integers) in the range 0 to */
/* base-1, or base if cp is does not represent a value.       */

static unsigned decode_digit(unsigned cp)
{
	return  cp - 48 < 10 ? cp - 22 :  cp - 65 < 26 ? cp - 65 :
	cp - 97 < 26 ? cp - 97 : base;
}

/* encode_digit(d,flag) returns the basic code point whose value      */
/* (when used for representing integers) is d, which needs to be in   */
/* the range 0 to base-1.  The lowercase form is used unless flag is  */
/* nonzero, in which case the uppercase form is used.  The behavior   */
/* is undefined if flag is nonzero and digit d has no uppercase form. */

static char encode_digit(unsigned d, int flag)
{
	return d + 22 + 75 * (d < 26) - ((flag != 0) << 5);
	/*  0..25 map to ASCII a..z or A..Z */
	/* 26..35 map to ASCII 0..9         */
}

/* flagged(bcp) tests whether a basic code point is flagged */
/* (uppercase).  The behavior is undefined if bcp is not a  */
/* basic code point.                                        */

#define flagged(bcp) ((unsigned)(bcp) - 65 < 26)

/* encode_basic(bcp,flag) forces a basic code point to lowercase */
/* if flag is zero, uppercase if flag is nonzero, and returns    */
/* the resulting code point.  The code point is unchanged if it  */
/* is caseless.  The behavior is undefined if bcp is not a basic */
/* code point.                                                   */

static char encode_basic(unsigned bcp, int flag)
{
	bcp -= (bcp - 97 < 26) << 5;
	return bcp + ((!flag && (bcp - 65 < 26)) << 5);
}

/*** Platform-specific constants ***/

/* maxint is the maximum value of a punycode_uint variable: */
static const unsigned maxint = UINT_MAX;
/* Because maxint is unsigned, -1 becomes the maximum value. */

/*** Bias adaptation function ***/

static unsigned adapt(unsigned delta, unsigned numpoints, BOOL firsttime) {
	unsigned k;
	
	delta = firsttime ? delta / damp : delta >> 1;
	/* delta >> 1 is a faster way of doing delta / 2 */
	delta += delta / numpoints;
	
	for (k = 0;  delta > ((base - tmin) * tmax) / 2;  k += base) {
		delta /= base - tmin;
	}
	
	return k + (base - tmin + 1) * delta / (delta + skew);
}

@interface NSString (PunycodePrivate)

- (NSDictionary *)URLParts;

@end

@implementation NSString (PunycodeAdditions)

/*** Main encode function ***/

- (const UTF32Char *)longCharactersWithCount:(NSUInteger *)count {
#if BYTE_ORDER == LITTLE_ENDIAN
	NSData *data = [self dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
#else
	NSData *data = [self dataUsingEncoding:NSUTF32BigEndianStringEncoding];
#endif
	*count = [data length] / sizeof(UTF32Char);
	return [data bytes];
}

- (NSString *)punycodeEncodedString {
	NSMutableString *ret = [NSMutableString string];
	unsigned n, delta, h, b, outLen, bias, j, m, q, k, t;
	NSUInteger input_length;// = [self length];
	const UTF32Char *longchars = [self longCharactersWithCount:&input_length];
	/* Initialize the state: */
	
	unsigned char *case_flags = NULL;
	
	n = initial_n;
	delta = outLen = 0;
	bias = initial_bias;
	
	/* Handle the basic code points: */
	
	for (j = 0;  j < input_length;  ++j) {
		if (basic(longchars[j])) {
			[ret appendFormat:@"%C",
				case_flags ? (unichar)encode_basic(longchars[j], case_flags[j]) : longchars[j]];
			++outLen;
		}
		/* else if ([self characterAtIndex:j] < n) return punycode_bad_input; */
		/* (not needed for Punycode with unsigned code points) */
	}
	
	h = b = outLen;
	
	/* h is the number of code points that have been handled, b is the  */
	/* number of basic code points, and out is the number of characters */
	/* that have been output.                                           */
	
	if (b > 0)
		[ret appendFormat:@"%C", delimiter];
	
	/* Main encoding loop: */
	
	while (h < input_length) {
		/* All non-basic code points < n have been     */
		/* handled already.  Find the next larger one: */
		
		for (m = maxint, j = 0;  j < input_length;  ++j) {
			/* if (basic([self characterAtIndex:j])) continue; */
			/* (not needed for Punycode) */
			unsigned c = longchars[j];
			
			if (c >= n && c < m)
				m = longchars[j];
		}
		
		/* Increase delta enough to advance the decoder's    */
		/* <n,i> state to <m,0>, but guard against overflow: */
		
		if (m - n > (maxint - delta) / (h + 1))
			return nil; //punycode_overflow;
		delta += (m - n) * (h + 1);
		n = m;
		
		for (j = 0;  j < input_length;  ++j) {
			unsigned c = longchars[j];
			
			/* Punycode does not need to check whether [self characterAtIndex:j] is basic: */
			if (c < n /* || basic([self characterAtIndex:j]) */ ) {
				if (++delta == 0)
					return nil; //punycode_overflow;
			}
			
			if (c == n) {
				/* Represent delta as a generalized variable-length integer: */
				
				for (q = delta, k = base;  ;  k += base) {
					t = k <= bias /* + tmin */ ? tmin :     /* +tmin not needed */
						k >= bias + tmax ? tmax : k - bias;
					if (q < t)
						break;
					[ret appendFormat:@"%C", encode_digit(t + (q - t) % (base - t), 0)];
					q = (q - t) / (base - t);
				}
				
				[ret appendFormat:@"%C", encode_digit(q, case_flags && case_flags[j])];
				bias = adapt(delta, h + 1, h == b);
				delta = 0;
				++h;
			}
		}
		
		++delta, ++n;
	}
	
	return ret;
}

/*** Main decode function ***/

- (NSString *)punycodeDecodedString {
	unsigned n, outLen, i, max_out, bias,
	b, j, inPos, oldi, w, k, digit, t;
	
	NSMutableData *utf32data = [NSMutableData data];
	
	unsigned char *case_flags = NULL;
	
	/* Initialize the state: */
	/*unsigned*/ NSUInteger input_length = [self length];
	n = initial_n;
	outLen = i = 0;
	max_out = UINT_MAX;
	bias = initial_bias;
	
	/* Handle the basic code points:  Let b be the number of input code */
	/* points before the last delimiter, or 0 if there is none, then    */
	/* copy the first b code points to the output.                      */
	
	for (b = j = 0;  j < input_length;  ++j)
		if (delim([self characterAtIndex:j]))
			b = j;
	
	if (b > max_out)
		return nil; //punycode_big_output;
	
	for (j = 0;  j < b;  ++j) {
		UTF32Char c = [self characterAtIndex:j];
		
		if (case_flags)
			case_flags[outLen] = flagged(c);
		if (!basic([self characterAtIndex:j]))
			return nil; //punycode_bad_input;
		
		
		[utf32data appendBytes:&c length:sizeof(c)];
		++outLen;
	}
	
	/* Main decoding loop:  Start just after the last delimiter if any  */
	/* basic code points were copied; start at the beginning otherwise. */
	
	for (inPos = b > 0 ? b + 1 : 0; inPos < input_length; ++outLen) {
		
		/* in is the index of the next character to be consumed, and */
		/* out is the number of code points in the output array.     */
		
		/* Decode a generalized variable-length integer into delta,  */
		/* which gets added to i.  The overflow checking is easier   */
		/* if we increase i as we go, then subtract off its starting */
		/* value at the end to obtain delta.                         */
		
		for (oldi = i, w = 1, k = base; /* nada */ ; k += base) {
			if (inPos >= input_length)
				return nil; // punycode_bad_input;
			digit = decode_digit([self characterAtIndex:inPos++]);
			if (digit >= base)
				return nil; // punycode_bad_input;
			if (digit > (maxint - i) / w)
				return nil; // punycode_overflow;
			i += digit * w;
			t = k <= bias /* + tmin */ ? tmin :     /* +tmin not needed */
				k >= bias + tmax ? tmax : k - bias;
			if (digit < t)
				break;
			if (w > maxint / (base - t))
				return nil; // punycode_overflow;
			w *= (base - t);
		}
		
		bias = adapt(i - oldi, outLen + 1, oldi == 0);
		
		/* i was supposed to wrap around from out+1 to 0,   */
		/* incrementing n each time, so we'll fix that now: */
		
		if (i / (outLen + 1) > maxint - n)
			return nil; // punycode_overflow;
		n += i / (outLen + 1);
		i %= (outLen + 1);
		
		/* Insert n at position i of the output: */
		
		/* not needed for Punycode: */
		/* if (decode_digit(n) <= base) return punycode_invalid_input; */
		
		if (case_flags) {
			memmove(case_flags + i + 1, case_flags + i, outLen - i);
			
			/* Case of last character determines uppercase flag: */
			case_flags[i] = flagged([self characterAtIndex:inPos - 1]);
		}
		
		//memmove(output + i + 1, output + i, (outLen - i) * sizeof *output);
		[utf32data replaceBytesInRange:NSMakeRange(i, 0) withBytes:&n length:sizeof(n)];
	}
		
	return [[[NSString alloc] initWithData:utf32data encoding:NSUTF32LittleEndianStringEncoding] autorelease];
}

- (NSString *)IDNAEncodedString {
	NSCharacterSet *nonAscii = [[NSCharacterSet characterSetWithRange:NSMakeRange(1,127)] invertedSet];
	NSMutableString *ret = [NSMutableString string];
	NSScanner *s = [NSScanner scannerWithString:[self precomposedStringWithCompatibilityMapping]];
	NSCharacterSet *dotAt = [NSCharacterSet characterSetWithCharactersInString:@".@"];
	NSString *input = nil;
	
	while (![s isAtEnd]) {
		if ([s scanUpToCharactersFromSet:dotAt intoString:&input]) {
			if ([input rangeOfCharacterFromSet:nonAscii].location != NSNotFound) {
				[ret appendFormat:@"xn--%@", [input punycodeEncodedString]];
			} else
				[ret appendString:input];
		}
		
		if ([s scanCharactersFromSet:dotAt intoString:&input])
			[ret appendString:input];
	}
		
	return ret;
}

- (NSString *)IDNADecodedString {
	NSMutableString *ret = [NSMutableString string];
	NSScanner *s = [NSScanner scannerWithString:self];
	NSCharacterSet *dotAt = [NSCharacterSet characterSetWithCharactersInString:@".@"];
	NSString *input = nil;
	
	while (![s isAtEnd]) {
		if ([s scanUpToCharactersFromSet:dotAt intoString:&input]) {
			if ([[input lowercaseString] hasPrefix:@"xn--"]) {
				NSString *substr = [[input substringFromIndex:4] punycodeDecodedString];
				
				if (substr)
					[ret appendString:substr];
			} else
				[ret appendString:input];
		}
		
		if ([s scanCharactersFromSet:dotAt intoString:&input])
			[ret appendString:input];
	}
	
	return ret;
}

- (NSDictionary *)URLParts {
	NSCharacterSet *colonSlash = [NSCharacterSet characterSetWithCharactersInString:@":/"];
	NSScanner *s = [NSScanner scannerWithString:[self precomposedStringWithCompatibilityMapping]];
	NSString *scheme = @"";
	NSString *delim = @"";
	NSString *host = @"";
	NSString *path = @"";
	NSString *fragment = nil;

	if ([s scanUpToCharactersFromSet:colonSlash intoString:&host]) {
		if (![s isAtEnd] && [self characterAtIndex:[s scanLocation]] == ':') {
			scheme = host;
			
			if (![s isAtEnd])
				[s scanCharactersFromSet:colonSlash intoString:&delim];
			if (![s isAtEnd])
				[s scanUpToString:@"/" intoString:&host];
		}
	}
	
	if (![s isAtEnd])
		[s scanUpToString:@"#" intoString:&path];

	if (![s isAtEnd]) {
		[s scanString:@"#" intoString:nil];
		[s scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&fragment];
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			scheme,		@"scheme",
			delim,		@"delim",
			host,		@"host",
			path,		@"path",
			fragment,	@"fragment",
			nil];
}

- (NSString *)encodedURLString {
	// We can't get the parts of an URL for an international domain name, so a custom method is used instead.
	NSDictionary *urlParts = [self URLParts];
	
	NSString *path = [[[urlParts objectForKey:@"path"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *ret = [NSString stringWithFormat:@"%@%@%@%@", [urlParts objectForKey:@"scheme"], [urlParts objectForKey:@"delim"], [[urlParts objectForKey:@"host"] IDNAEncodedString], path];
	
	if ([urlParts objectForKey:@"fragment"])
		ret = [ret stringByAppendingFormat:@"#%@", [urlParts objectForKey:@"fragment"]];
		
	return ret;
}

- (NSString *)decodedURLString {
	NSDictionary *urlParts = [self URLParts];
	
	NSString *ret = [NSString stringWithFormat:@"%@%@%@%@", [urlParts objectForKey:@"scheme"], [urlParts objectForKey:@"delim"], [[urlParts objectForKey:@"host"] IDNADecodedString], [[urlParts objectForKey:@"path"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	if ([urlParts objectForKey:@"fragment"])
		ret = [ret stringByAppendingFormat:@"#%@", [urlParts objectForKey:@"fragment"]];
	
	return ret;
}

@end

@implementation NSURL (PunycodeAdditions)

- (NSString *)decodedURLString {
	return [[self absoluteString] decodedURLString];
}

@end
