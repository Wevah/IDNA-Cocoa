//
//  NSStringPunycodeAdditions.h
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005-2012 Derailer. All rights reserved.
//
//  Distributed under an MIT-style license; please
//  see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>


@interface NSString (PunycodeAdditions)

/*!
 @property
 @abstract	Converts a Unicode string to its Punycode equivalent.
 @return	The equivalent punycode-encoded string.
 */
@property (readonly, copy)	NSString *punycodeEncodedString;
/*!
 @property
 @abstract	Converts a Punycode-encoded string to its Unicode equivalent.
 @return	The equivalent Unicode string, or <tt>nil</tt> if <tt>self</tt> is not a valid Punycode-encoded string.
 */
@property (readonly, copy)	NSString *punycodeDecodedString;

/*!
 @property
 @abstract		Converts a Unicode domain to its encoded equivalent.
 @return		The equivalent IDNA-encoded domain.
 @discussion	This will properly split domains on periods; e.g., “www.bücher.ch” becomes “www.xn--bcher-kva.ch”.
 */
@property (readonly, copy) NSString *IDNAEncodedString;
/*!
 @property
 @abstract		Converts an IDNA-encoded domain to its Unicode equivalent.
 @return		The equivalent Unicode domain.
 @discussion	This will properly split domains on periods; e.g., “www.xn--bcher-kva.ch” becomes “www.bücher.ch”.
 */
@property (readonly, copy) NSString *IDNADecodedString;

/*!
 @property
 @abstract		Converts a Unicode URL string to its encoded equivalent.
 @discussion	This method currently expects <tt>self</tt> to start with a valid scheme (e.g., "http:").
 @return		The equivalent IDNA- and percent-encoded URL string.
 */
@property (readonly, copy) NSString *encodedURLString;
/*!
 @property
 @abstract		Converts an encoded URL string to its Unicode equivalent.
 @discussion	This method currently expects <tt>self</tt> to start with a valid scheme (e.g., "http:").
 @return		The equivalent Unicode URL string.
 */
@property (readonly, copy) NSString *decodedURLString;

@end

@interface NSURL (PunycodeAdditions)

/*!
 @property
 @abstract		Initializes an URL with a Unicode URL string.
 @discussion	Equivalent to <tt>[NSURL URLWithString:URLString.encodedURLString]</tt>.
 @return		An encoded NSURL.
 */
+ (instancetype)URLWithUnicodeString:(NSString *)URLString;
/*!
 @property
 @abstract		Converts an NSURL to its IDNA- and percent-decoded form.
 @discussion	Equivalent to <tt>self.absoluteString.decodedURLString</tt>.
 @return		A decoded URL string.
 */
@property (readonly, copy) NSString *decodedURLString;

@end
