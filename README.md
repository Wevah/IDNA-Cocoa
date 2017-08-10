Punycode Cocoa
==============

[![Build Status](https://travis-ci.org/Wevah/Punycode-Cocoa.svg?branch=master)](https://travis-ci.org/Wevah/Punycode-Cocoa)

v1.3 (2017)  
by Nate Weaver (Wevah)  
https://derailer.org/  
https://github.com/Wevah/Punycode-Cocoa

A simple punycode/IDNA category on NSString, based on code and documentation from RFC 3492 and RFC 3490.

Use this to convert internationalized domain names (IDN) between Unicode and ASCII.

To use in your own projects, all you need is `NSStringPunycodeAdditions.h/m`. This project includes a sample testing app.

Macros
------

Define `PUNYCODE_COCOA_USE_WEBKIT` to have Punycode Cocoa methods call internal WebKit methods instead of the custom implementations. Useful if you're already linking against WebKit, or want additional homograph attack protection.

Methods
-------

NSString
--------

	@property (readonly, copy, nullable)	NSString *punycodeEncodedString;
	@property (readonly, copy, nullable)	NSString *punycodeDecodedString;

Encodes or decodes a string to its punycode-encoded format, stripping variation selectors (`U+FE00`–`U+FE15`).
	
	@property (readonly, copy, nullable) NSString *IDNAEncodedString;
	
If `self` contains non-ASCII, calls `-punycodeEncodedString` and prepends `xn--`.

	@property (readonly, copy, nullable) NSString *IDNADecodedString;

Decodes a string returned by `-IDNAEncodedString`.

	@property (readonly, copy, nullable) NSString *encodedURLString;
	@property (readonly, copy, nullable) NSString *decodedURLString;
	
Performs encode/decode operations on each appropriate part (the domain bits) of an URL string.

NSURL
-----
	
	+ (instancetype nullable)URLWithUnicodeString:(NSString *)URLString;
	
Convenience method equivalent to `[NSURL URLWithString:URLString.encodedURLString]`.
	
	@property (readonly, copy, nullable) NSString *decodedURLString;

Convenience property equivalent to `anURL.absoluteString.decodedURLString`.

----

© 2012–2017 Nate Weaver (Wevah)
