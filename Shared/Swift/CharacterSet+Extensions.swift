//
//  CharacterSet+Extensions.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-04-20.
//

import Foundation

extension CharacterSet {

	/// Convert a character set to a string with character range pairs of the form
	/// `[start][end] ...`
	func rangeStringData() -> Data {
		var str = String()

		var startChar: UnicodeScalar?
		var lastChar: UnicodeScalar?

		for i in 0...0x10FFFF {
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

		return str.data(using: .utf8)!
	}

}
