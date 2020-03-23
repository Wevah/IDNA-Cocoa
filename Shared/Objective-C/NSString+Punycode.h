//
//  NSString+Punycode.h
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005-2012 Derailer. All rights reserved.
//
//  Distributed under an MIT-style license; please
//  see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Punycode)

/*!
 @property
 @abstract		Converts a Unicode domain to its encoded equivalent.
 @return		The equivalent IDNA-encoded domain.
 @discussion	This will properly split domains on periods; e.g., “www.bücher.ch” becomes “www.xn--bcher-kva.ch”.
 */
@property (readonly, copy, nullable) NSString *IDNAEncodedString;
/*!
 @property
 @abstract		Converts an IDNA-encoded domain to its Unicode equivalent.
 @return		The equivalent Unicode domain.
 @discussion	This will properly split domains on periods; e.g., “www.xn--bcher-kva.ch” becomes “www.bücher.ch”.
 */
@property (readonly, copy, nullable) NSString *IDNADecodedString;

/*!
 @property
 @abstract		Converts a Unicode URL string to its encoded equivalent.
 @discussion	This method currently expects \c self to start with a valid scheme (e.g., "http:").
 @return		The equivalent IDNA- and percent-encoded URL string.
 */
@property (readonly, copy, nullable) NSString *encodedURLString;
/*!
 @property
 @abstract		Converts an encoded URL string to its Unicode equivalent.
 @discussion	This method currently expects \c self to start with a valid scheme (e.g., "http:").
 @return		The equivalent Unicode URL string.
 */
@property (readonly, copy, nullable) NSString *decodedURLString;

@end

@interface NSURL (Punycode)

/*!
 @method
 @abstract		Initializes an URL with a Unicode URL string.
 @discussion	Equivalent to <tt>[NSURL URLWithString:URLString.encodedURLString]</tt>.
 @return		An encoded NSURL.
 */
+ (nullable instancetype)URLWithUnicodeString:(NSString *)URLString;
/*!
 @property
 @abstract		Converts an NSURL to its IDNA- and percent-decoded form.
 @discussion	Equivalent to <tt>self.absoluteString.decodedURLString</tt>.
 @return		A decoded URL string.
 */
@property (readonly, copy, nullable) NSString *decodedURLString;

/*!
 @method
 @abstract		Creates a URL from a relative Unicode string and a base URL.
 @return		An encoded URL.
 */
+ (nullable instancetype)URLWithUnicodeString:(NSString *)URLString relativeToURL:(nullable NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
