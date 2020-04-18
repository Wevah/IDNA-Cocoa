# Punycode Cocoa

[![Build Status](https://travis-ci.org/Wevah/Punycode-Cocoa.svg?branch=master)](https://travis-ci.org/Wevah/Punycode-Cocoa)

v2.0 (2020)
by Nate Weaver (Wevah)  
https://derailer.org/  
https://github.com/Wevah/Punycode-Cocoa

A simple punycode/IDNA String extension and NSString category, based on code and documentation from RFC 3492 and RFC 3490.

Use this to convert internationalized domain names (IDN) between Unicode and ASCII.

To use in your own projects, all you need is `String+Punycode.swift` or `NSString+Punycode.h/m`. This project includes a sample testing app.

The Objective-C `NSString+Punycode` files are compatible with both ARC and Manual Retain Release modes.

**Note:** The Objective-C implementation currently on `master` is pretty out-of-date, but the Swift version has appropriate  `@objc` extensions. I may update the Objective-C implementation eventually!

Note that these API currently don't do homograph detection.

## Macros (Objective-C only)

Define `PUNYCODE_COCOA_USE_WEBKIT` to have Punycode Cocoa methods call internal WebKit methods instead of the custom implementations. Useful if you're already linking against WebKit, or want additional homograph attack protection. However, this probably won't be allowed on the App Store due to its use of private methods.

Define `PUNYCODE_COCOA_USE_ICU` to use ICU (by default the system's ICU). Using the system ICU may get your app rejected if you intend put it on the App Store. Compiling and bundling your own ICU libs (from http://sute.icu-project.org/) is almost certainly allowed, though you will want to build NSString+Punycode with the headers from your downloaded library/source.

## Interface

### String/NSString

###### Swift:
```swift
var idnaEncoded: String? { get }
```

###### Objective-C:
```objc
@property (readonly, copy, nullable) NSString *IDNAEncodedString;
```

If `self` contains non-ASCII, encodes the string's domain components as Punycode and prepends `xn--` to the transformed components.

-----

###### Swift:
```swift
var idnaDecoded: String? { get }
```

###### Objective-C:
```objc
@property (readonly, copy, nullable) NSString *IDNADecodedString;
```

Decodes a string returned by `idnaEncoded`/`-IDNAEncodedString`.

-----

###### Swift:
```swift
var encodedURLString: String? { get }
var decodedURLString: String? { get }
```

###### Objective-C:
```objc
@property (readonly, copy, nullable) NSString *encodedURLString;
@property (readonly, copy, nullable) NSString *decodedURLString;
```

Performs Punycode encode/decode operations on each appropriate part (the domain bits) of an URL string, and URL encodes/decodes the path/query/fragment.

-----

### URL/NSURL

###### Swift:
```swift
init?(unicodeString: String)
```

###### Objective-C:
```objc
+ (nullable instancetype)URLWithUnicodeString:(NSString *)URLString;
```
	
Convenience initializer equivalent to `URL(string: unicodeString.encodedURLString)`/ `[NSURL URLWithString:URLString.encodedURLString]`.

-----

###### Swift:
```swift
var decodedURLString: String? { get }
```

###### Objective-C:
```objc
@property (readonly, copy, nullable) NSString *decodedURLString;
```

Convenience property equivalent to `someURL.absoluteString.decodedURLString`.

-----

##### Swift:
```swift
init?(unicodeString: String, relativeTo url: URL?) {
```

##### Objective-C: 
```objc
+ (nullable instancetype)URLWithUnicodeString:(NSString *)URLString relativeToURL:(nullable NSURL *)baseURL;
```

Convenience initializer for creating a URL from a Unicode string, relative to another URL.

-----

© 2012–2020 Nate Weaver (Wevah)
