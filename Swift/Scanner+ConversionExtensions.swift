//
//  Scanner+Extensions.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-07-02.
//

import Foundation

extension Scanner {

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
