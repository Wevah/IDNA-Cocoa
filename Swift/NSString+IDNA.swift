//
//  NSString+IDNA.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-04-18.
//

import Foundation

@objc public extension NSString {
	@objc(IDNAEncodedString) var idnaEncoded: String? { (self as String).idnaEncoded }
	@objc(IDNADecodedString) var idnaDecoded: String? { (self as String).idnaDecoded }
	var encodedURLString: String? { (self as String).encodedURLString }
	var decodedURLString: String? { (self as String).decodedURLString }
}

@objc public extension NSURL {
	@objc(URLWithUnicodeString:) static func urlWithUnicodeString(_ unicodeString: String) -> URL? {
		return URL(unicodeString: unicodeString)
	}

	var decodedURLString: String? {
		return (self as URL).decodedURLString
	}

	@objc(URLWithUnicodeString:relativeToURL:) static func urlWithUnicodeString(_ unicodeString: String, relativeTo url: URL) -> URL? {
		return URL(unicodeString: unicodeString, relativeTo: url)
	}
}
