//
//  Scanner+Extensions.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-04-20.
//

import Foundation

// Wrapper functions for < 10.15 compatibility
// TODO: Remove when support for < 10.15 is dropped.
extension Scanner {

	func shimScanUpToCharacters(from set: CharacterSet) -> String? {
		if #available(macOS 10.15, iOS 13.0, *) {
			return self.scanUpToCharacters(from: set)
		} else {
			var str: NSString?
			self.scanUpToCharacters(from: set, into: &str)
			return str as String?
		}
	}

	func shimScanCharacters(from set: CharacterSet) -> String? {
		if #available(macOS 10.15, iOS 13.0, *) {
			return self.scanCharacters(from: set)
		} else {
			var str: NSString?
			self.scanCharacters(from: set, into: &str)
			return str as String?
		}
	}

	func shimScanUpToString(_ substring: String) -> String? {
		if #available(macOS 10.15, iOS 13.0, *) {
			return self.scanUpToString(substring)
		} else {
			var str: NSString?
			self.scanUpTo(substring, into: &str)
			return str as String?
		}
	}

	func shimScanString(_ searchString: String) -> String? {
		if #available(macOS 10.15, iOS 13.0, *) {
			return self.scanString(searchString)
		} else {
			var str: NSString?
			self.scanString(searchString, into: &str)
			return str as String?
		}
	}

	enum ShimNumberRepresentation {
		case decimal
		case hexadecimal
	}

	func shimScanInt(representation: ShimNumberRepresentation) -> Int? {
		if #available(macOS 10.15, iOS 13.0, *) {
			let realRepresentation: Scanner.NumberRepresentation

			switch representation {
				case .decimal:
					realRepresentation = .decimal
				case .hexadecimal:
					realRepresentation = .hexadecimal
			}

			return self.scanInt(representation: realRepresentation)
		} else {
			switch representation {
				case .decimal:
					var int: Int = 0
					if self.scanInt(&int) { return int }
				case .hexadecimal:
					var int: UInt64 = 0
					if self.scanHexInt64(&int) { return Int(int) }
			}

			return nil
		}
	}

}

extension Scanner {

	/// Scans a range of the form `hex[..hex]`.
	func scanHexRange() -> ClosedRange<Int>? {
		guard let start = self.shimScanInt(representation: .hexadecimal) else { return nil }

		var end = start

		if self.shimScanString("..") != nil {
			guard let temp = self.shimScanInt(representation: .hexadecimal) else { return nil }

			end = temp
		}

		return start...end
	}

}
