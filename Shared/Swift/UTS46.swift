//
//  UTS46.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-03-29.
//

import Foundation
import Compression

enum UTS46 {

	private(set) static var characterMap: [UInt32: String] = [:]
	private(set) static var ignoredCharacters: CharacterSet = []
	private(set) static var disallowedCharacters: CharacterSet = []
	private(set) static var joiningTypes = [UInt32: JoiningType]()

	private enum Marker {
		static let characterMap = UInt8.max
		static let ignoredCharacters = UInt8.max - 1
		static let disallowedCharacters = UInt8.max - 2
		static let joiningTypes = UInt8.max - 3

		static let min = UInt8.max - 10 // No valid UTF-8 byte can fall here.

		static let sequenceTerminator: UInt8 = 0
	}

	enum JoiningType: Character {
		case causing = "C"
		case dual = "D"
		case right = "R"
		case left = "L"
		case transparent = "T"
	}

	enum UTS46Error: Error {
		case badSize
		case decompressionError
		case badMarker
	}

	enum CompressionAlgorithm {
		case lzfse
		case lz4
		case lzma
		case zlib
	}

	static func load(from url: URL, compression: CompressionAlgorithm?) throws {
		let compressedData = try Data(contentsOf: url)

		guard let data = self.decompress(data: compressedData, algorithm: compression) else {
			throw UTS46Error.decompressionError
		}

		if data.count % 4 != 0 {
			throw UTS46Error.badSize
		}

		var index = 0

		while index < data.count {
			let marker = data[index]

			index += 1

			switch marker {
				case Marker.characterMap:
					index = parseCharacterMap(from: data, start: index)
				case Marker.ignoredCharacters:
					index = parseIgnoredCharacters(from: data, start: index)
				case Marker.disallowedCharacters:
					index = parseDisallowedCharacters(from: data, start: index)
				case Marker.joiningTypes:
					index = parseJoiningTypes(from: data, start: index)
				default:
					throw UTS46Error.badMarker
			}
		}

	}

	private static func decompress(data: Data, algorithm: CompressionAlgorithm?) -> Data? {

		var rawAlgorithm: compression_algorithm

		switch algorithm {
			case .lzfse:
				rawAlgorithm = COMPRESSION_LZFSE
			case .lz4:
				rawAlgorithm = COMPRESSION_LZ4
			case .lzma:
				rawAlgorithm = COMPRESSION_LZMA
			case .zlib:
				rawAlgorithm = COMPRESSION_ZLIB
			default:
				return data

		}

		let capacity = 100_000
		let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)

		let decompressed = data.withUnsafeBytes { (rawBuffer) -> Data? in
			let bound = rawBuffer.bindMemory(to: UInt8.self)
			let decodedCount = compression_decode_buffer(destinationBuffer, capacity, bound.baseAddress!, rawBuffer.count, nil, rawAlgorithm)

			if decodedCount == 0 {
				return nil
			}

			return Data(bytes: destinationBuffer, count: decodedCount)
		}

		return decompressed
	}

	private static func parseCharacterMap(from data: Data, start: Int) -> Int {
		characterMap.removeAll()
		var index = start

		main: while index < data.count {
			var accumulator = Data()

			while data[index] != Marker.sequenceTerminator {
				if data[index] > Marker.min { break main }

				accumulator.append(data[index])
				index += 1
			}

			let str = String(data: accumulator, encoding: .utf8)!

			// FIXME: throw an error here.
			guard str.count > 0 else { continue }
			
			let codepoint = str.unicodeScalars.first!.value

			characterMap[codepoint] = String(str.unicodeScalars.dropFirst())

			index += 1
		}

		return index
	}

	private static func parseRanges(from: String) -> [ClosedRange<UnicodeScalar>]? {
		guard from.unicodeScalars.count % 2 == 0 else { return nil }

		var ranges = [ClosedRange<UnicodeScalar>]()
		var first: UnicodeScalar? = nil

		for (index, scalar) in from.unicodeScalars.enumerated() {
			if index % 2 == 0 {
				first = scalar
			} else if let first = first {
				ranges.append(first...scalar)
			}
		}

		return ranges
	}

	static func parseCharacterSet(from data: Data, start: Int) -> (index: Int, charset: CharacterSet?) {
		var index = start
		var accumulator = Data()

		while index < data.count, data[index] < Marker.min {
			accumulator.append(data[index])
			index += 1
		}

		let str = String(data: accumulator, encoding: .utf8)!

		guard let ranges = parseRanges(from: str) else {
			return (index: index, charset: nil)
		}

		var charset = CharacterSet()

		for range in ranges {
			charset.insert(charactersIn: range)
		}

		return (index: index, charset: charset)
	}


	static func parseIgnoredCharacters(from data: Data, start: Int) -> Int {
		let (index, charset) = parseCharacterSet(from: data, start: start)

		if let charset = charset {
			ignoredCharacters = charset
		}

		return index
	}

	static func parseDisallowedCharacters(from data: Data, start: Int) -> Int {
		let (index, charset) = parseCharacterSet(from: data, start: start)

		if let charset = charset {
			disallowedCharacters = charset
		}

		return index
	}

	static func parseJoiningTypes(from data: Data, start: Int) -> Int {
		var index = start
		joiningTypes.removeAll()

		main: while index < data.count, data[index] < Marker.min {
			var accumulator = Data()

			while index < data.count {
				if data[index] > Marker.min { break main }
				accumulator.append(data[index])

				index += 1
			}

			let str = String(data: accumulator, encoding: .utf8)!

			var type: JoiningType?
			var first: UnicodeScalar? = nil

			for scalar in str.unicodeScalars {
				if scalar.isASCII {
					type = JoiningType(rawValue: Character(scalar))
				} else if let type = type {
					if first == nil {
						first = scalar
					} else {
						for value in first!.value...scalar.value {
							joiningTypes[value] = type
						}

						first = nil
					}
				}
			}
		}

		return index
	}

}
