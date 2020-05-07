//
//  CharacterSet+Extensions.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-04-20.
//

import Foundation

extension CharacterSet {

	/// Convert a character set to UTF-8 data with character range pairs of the form
	/// `[start][end] ...`
	///
	/// Ranges of length 1 will use the same character for start and end.
	/// 
	/// Example:
	/// ```
	/// let charset = CharacterSet(charactersIn: "abcdefgmwxyz")
	///
	/// let data = charset.rangeStringData()
	/// // data is "agmmwz" (UTF-8 encoded)
	/// ```
	func rangeStringData() -> Data {
		var str = String()

		var startChar: UnicodeScalar?
		var lastChar: UnicodeScalar?

		// Skip surrogate codepoints
		for range in [0...0xD7FF, 0xE000...0x10FFFF] {
			for i in range {
				if let c = UnicodeScalar(i) {
					if self.contains(c) {
						if startChar == nil {
							startChar = c
						}

						lastChar = c
					} else if let start = startChar, let last = lastChar {
						str.unicodeScalars.append(start)
						str.unicodeScalars.append(last)

						startChar = nil
						lastChar = nil
					}
				}
			}
		}

		return str.data(using: .utf8)!
	}

}
