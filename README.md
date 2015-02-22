Punycode Cocoa
==============

v1.1 (2015)
by Nate Weaver (Wevah)
http://derailer.org/
https://github.com/Wevah/Punycode-Cocoa

A simple punycode/IDNA category on NSString, based on code and documentation from RFC 3492 and RFC 3490.

Use this to convert internationalized domain names (IDN) between Unicode and ASCII.

To use in your own projects, all you need is `NSStringPunycodeAdditions.h/m`. This project includes a sample testing app.

Methods
-------

NSString
--------

	@property (readonly, copy)	NSString *punycodeEncodedString;
	@property (readonly, copy)	NSString *punycodeDecodedString;

Encodes or decodes a string to its punycode-encoded format.
	
	@property (readonly, copy) NSString *IDNAEncodedString;
	
If `self` contains non-ASCII, calls `-punycodeEncodedString` and prepends `xn--`.

	@property (readonly, copy) NSString *IDNADecodedString;

Decodes a string returned by `-IDNAEncodedString`.

	@property (readonly, copy) NSString *encodedURLString;
	@property (readonly, copy) NSString *decodedURLString;
	
Performs encode/decode operations on each appropriate part (the domain bits) of an URL string.

NSURL
-----
	
	+ (instancetype)URLWithUnicodeString:(NSString *)URLString;
	
Convenience method equivalent to `[NSURL URLWithString:URLString.encodedURLString]`.
	
	@property (readonly, copy) NSString *decodedURLString;

Convenience property equivalent to `anURL.absoluteString.decodedURLString`.

----

© 2012-2015 Nate Weaver (Wevah)
