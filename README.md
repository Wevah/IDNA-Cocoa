Punycode Cocoa
==============

by Nate Weaver (Wevah)
http://derailer.org/
https://github.com/Wevah/Punycode-Cocoa

A simple punycode/IDNA category on NSString, based on code and documentation from RFC 3492 and RFC 3490.

To use in your own projects, all you need is NSStringPunycodeAdditions.h/m. This project includes a sample testing app.

Methods
-------

NSString
--------

	- (NSString *)punycodeEncodedString;
	- (NSString *)punycodeDecodedString;
	
Encodes or decodes a string to its punycode-encoded format.
	
	- (NSString *)IDNAEncodedString;
	
If `self` contains non-ASCII, calls `-punycodeEncodedString` and prepends `xn--`.

	- (NSString *)IDNADecodedString;

Decodes a string returned by `-IDNAEncodedString`.

	- (NSString *)encodedURLString;
	- (NSString *)decodedURLString;
	
Performs encode/decode operations on each appropriate part (the domain bits) of an URL string.

NSURL
-----

	- (NSString *)decodedURLString;

Convenience method on NSURL. Equivalent to `[[anURL absoluteString] decodedURLString]`.