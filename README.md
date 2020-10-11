# Punycode Cocoa

[![Build Status](https://travis-ci.org/Wevah/Punycode-Cocoa.svg?branch=master)](https://travis-ci.org/Wevah/Punycode-Cocoa)

v2.0b3 (2020)
by Nate Weaver (Wevah)  
https://derailer.org/  
https://github.com/Wevah/Punycode-Cocoa

An IDNA String extension and NSString overlay, based on [UTS #46](https://unicode.org/reports/tr46/).

Use this to convert internationalized domain names (IDN) between Unicode and ASCII.

To use in your own projects, you need to include some files from the `Shared/Swift` folder, and make sure the `uts46` data file is copied to your application's `Resources` folder. The required Swift files are:

- UTS46.swift
- UTS46+Loading.swift
- Data+Extensions.swift
- Scanner+Extensions.swift
- String+Punycode.swift

If your project needs to call from Objective-C:

- NSString+IDNA.swift for NSString overlays.

(UTS46+Conversion.swift is for importing text files containing UTS #46 mappings and exporting to the binary format used by UTS46+Loading.swift, and isn't necessary if you just want to use the encoding/decoding routines.)

Note that these API currently don't do homograph detection.

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
