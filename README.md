# IDNA Cocoa

v2.0b4 (2021)
by Nate Weaver (Wevah)  
https://derailer.org/  
https://github.com/Wevah/Punycode-Cocoa

![Swift](https://github.com/Wevah/IDNA-Cocoa/workflows/Swift/badge.svg)

**Note: This package (or similar packages) is no longer necessary when targeting macOS 14+/iOS 17+/etc., as `(NS)URL` has been updated to do IDNA encoding. It's also possible to use `(NS)URLComponents` on macOS 13+/iOS 16+/etc., as it does IDNA encoding on those OS versions.**

An IDNA String extension and NSString overlay, based on [UTS #46](https://unicode.org/reports/tr46/). Currently implents the full conversion table and joiner validation.

Use this to convert internationalized domain names (IDN) between Unicode and ASCII.

To use in your own projects, this repository can be imported as a Swift package.

Alternatively, the files can be manually included: Everything in `Sources/IDNA`:

- UTS46.swift
- UTS46+Loading.swift
- Data+Extensions.swift
- Scanner+Extensions.swift
- String+Punycode.swift

If your project needs to call from Objective-C make sure to include `NSString+IDNA.swift` for the `NSString` overlays.

(`UTS46+Conversion.swift` is for importing text files containing UTS #46 mappings and exporting to the binary format used by `UTS46+Loading.swift`, and isn't necessary if you just want to use the encoding/decoding routines.)

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

© 2012–2022 Nate Weaver (Wevah)
