//
//  Data+Extensions.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-04-12.
//

import Foundation
import zlib

extension Data {

	/// Compute the CRC-32 of the data.
	///
	/// Does not handle data with a `count` larger than `UInt32.max` on macOS
	/// < 10.13 or on iOS < 11.0.
	var crc32: UInt32 {
		return self.withUnsafeBytes {
			let buffer = $0.bindMemory(to: UInt8.self)

			if #available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
				let initial = zlib.crc32_z(0, nil, 0)
				return UInt32(zlib.crc32_z(initial, buffer.baseAddress, buffer.count))
			} else {
				let initial = zlib.crc32(0, nil, 0)
				return UInt32(zlib.crc32(initial, buffer.baseAddress, UInt32(buffer.count)))
			}
		}
	}

}
