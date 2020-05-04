//
//  UTS46.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-03-29.
//

import Foundation
import Compression

class UTS46 {

	private(set) static var characterMap: [UInt32: String] = [:]
	private(set) static var ignoredCharacters: CharacterSet = []
	private(set) static var disallowedCharacters: CharacterSet = []
	private(set) static var joiningTypes = [UInt32: JoiningType]()

	private static var isLoaded = false

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
		case compressionError
		case decompressionError
		case badMarker
		case unknownDataVersion
	}

	/// Identical values to `NSData.CompressionAlgorithm + 1`.
	enum CompressionAlgorithm: UInt8 {
		case none = 0
		case lzfse = 1
		case lz4 = 2
		case lzma = 3
		case zlib = 4

		var rawAlgorithm: compression_algorithm? {
			switch self {
				case .lzfse:
					return COMPRESSION_LZFSE
				case .lz4:
					return COMPRESSION_LZ4
				case .lzma:
					return COMPRESSION_LZMA
				case .zlib:
					return COMPRESSION_ZLIB
				default:
					return nil
			}

		}
	}

	private struct Header: RawRepresentable, CustomDebugStringConvertible {
		typealias RawValue = [UInt8]

		var rawValue: [UInt8] {
			let value = Self.signature + [version, flags.rawValue]
			assert(value.count == 8)
			return value
		}

		private static let compressionMask: UInt8 = 0x07
		private static let signature: [UInt8] = Array("UTS#46".utf8)

		private struct Flags: RawRepresentable {
			var rawValue: UInt8 {
				return (hasCRC ? hasCRCMask : 0) | compression.rawValue
			}

			var hasCRC: Bool
			var compression: CompressionAlgorithm

			private let hasCRCMask: UInt8 = 1 << 3
			private let compressionMask: UInt8 = 0x7

			init(rawValue: UInt8) {
				hasCRC = rawValue & hasCRCMask != 0
				let compressionBits = rawValue & compressionMask

				compression = CompressionAlgorithm(rawValue: compressionBits) ?? .none
			}

			init(compression: CompressionAlgorithm = .none, hasCRC: Bool = false) {
				self.compression = compression
				self.hasCRC = hasCRC
			}
		}

		let version: UInt8
		private var flags: Flags
		var hasCRC: Bool { flags.hasCRC }
		var compression: CompressionAlgorithm { flags.compression }
		var dataOffset: Int { 8 + (flags.hasCRC ? 4 : 0) }

		init?<T: DataProtocol>(rawValue: T) where T.Index == Int {
			guard rawValue.count == 8 else { return nil }
			guard rawValue.prefix(Self.signature.count).elementsEqual(Self.signature) else { return nil }

			version = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 6)]
			flags = Flags(rawValue: rawValue[rawValue.index(rawValue.startIndex, offsetBy: 7)])
		}

		init(compression: CompressionAlgorithm = .none, hasCRC: Bool = false) {
			self.version = 1
			self.flags = Flags(compression: compression, hasCRC: hasCRC)
		}

		var debugDescription: String { "has CRC: \(hasCRC); compression: \(String(describing: compression))" }
	}

}

extension UTS46 {

	private static func parseHeader(from data: Data) throws -> Header? {
		let headerData = data.prefix(8)

		guard headerData.count == 8 else { throw UTS46Error.badSize }

		return Header(rawValue: headerData)
	}

	static func load(from url: URL) throws {
		let fileData = try Data(contentsOf: url)

		guard let header = try? parseHeader(from: fileData) else { return }

		guard header.version == 1 else { throw UTS46Error.unknownDataVersion }

		let offset = header.dataOffset

		guard fileData.count > offset else { throw UTS46Error.badSize }

		let compressedData = fileData[offset...]

		guard let data = self.decompress(data: compressedData, algorithm: header.compression) else {
			throw UTS46Error.decompressionError
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

		isLoaded = true
	}

	static func loadIfNecessary() throws {
		guard !isLoaded else { return }
		guard let url = Bundle(for: Self.self).url(forResource: "uts46", withExtension: nil) else { throw CocoaError(.fileNoSuchFile) }

		try load(from: url)
	}

	private static func decompress(data: Data, algorithm: CompressionAlgorithm?) -> Data? {

		guard let rawAlgorithm = algorithm?.rawAlgorithm else { return data }

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

extension UTS46 {

	static func readCharacterMap(fromTextFile file: URL) throws {

		guard let text = try? String(contentsOf: file) else {
			print("Couldn't read from '\(file)'")
			throw CocoaError(.fileNoSuchFile)
		}

		characterMap.removeAll()
		disallowedCharacters = []
		ignoredCharacters = []

		let scanner = Scanner(string: text)

		while !scanner.isAtEnd {
			defer { let _ = scanner.shimScanUpToCharacters(from: .newlines) }

			guard let range = scanner.scanHexRange() else { continue }

			guard scanner.shimScanString(">") != nil else {
				continue
			}

			var mapped = ""

			var isDisallowed = false

			while let scanned = scanner.shimScanInt(representation: .hexadecimal) {
				if scanned == 0xFFFD {
					isDisallowed = true
					break
				}

				mapped.unicodeScalars.append(UnicodeScalar(scanned)!)
			}

			let isIgnored = mapped.count == 0

			if isDisallowed {
				disallowedCharacters.insert(charactersIn: UnicodeScalar(range.lowerBound)!...UnicodeScalar(range.upperBound)!)
			} else if isIgnored {
				ignoredCharacters.insert(charactersIn: UnicodeScalar(range.lowerBound)!...UnicodeScalar(range.upperBound)!)
			} else {
				for codepoint in range {
					characterMap[UInt32(codepoint)] = mapped
				}
			}
		}
	}

	static func readJoinerTypes(fromTextFile file: URL) throws {

		guard let text = try? String(contentsOf: file) else {
			print("Couldn't read from '\(file)'")
			throw CocoaError(.fileNoSuchFile)
		}

		joiningTypes.removeAll()

		let scanner = Scanner(string: text)

		let joiningTypeCharacters = CharacterSet(charactersIn: "CDRLT")

		while !scanner.isAtEnd {
			defer { let _ = scanner.shimScanUpToCharacters(from: .newlines) }

			guard let range = scanner.scanHexRange() else { continue }

			guard let _ = scanner.shimScanString(";") else { continue }

			guard let joiningType = scanner.shimScanCharacters(from: joiningTypeCharacters),
				joiningType.count == 1 else { continue }

			for codepoint in range {
				joiningTypes[UInt32(codepoint)] = JoiningType(rawValue: joiningType.first!)!
			}
		}
	}

	private static func characterMapData() -> Data {
		var data = Data()

		for key in characterMap.keys.sorted() {
			data.append(contentsOf: key.utf8)

			let value = characterMap[key]!
			data.append(contentsOf: value.utf8)
			data.append(Marker.sequenceTerminator)
		}

		return data
	}

	private static func disallowedCharactersData() -> Data {
		return disallowedCharacters.rangeStringData()
	}

	private static func ignoredCharactersData() -> Data {
		return ignoredCharacters.rangeStringData()
	}

	private static func joiningTypesData() -> Data {
		var reverseMap: [Character: String] = ["C": "", "D": "", "L": "", "R": "", "T": ""]

		for (codepoint, joiningType) in joiningTypes {
			reverseMap[joiningType.rawValue]?.unicodeScalars.append(UnicodeScalar(codepoint)!)
		}

		reverseMap = reverseMap.mapValues {
			var str = ""
			var firstScalar: UnicodeScalar? = nil
			var lastScalar: UnicodeScalar? = nil

			for scalar in $0.unicodeScalars.sorted() {
				if firstScalar == nil {
					firstScalar = scalar
				} else if let first = firstScalar, let last = lastScalar {
					if scalar.value - last.value > 1 {
						str.unicodeScalars.append(first)
						str.unicodeScalars.append(last)

						firstScalar = scalar
					}
				}

				lastScalar = scalar
			}

			if let first = firstScalar, let last = lastScalar {
				str.unicodeScalars.append(first)
				str.unicodeScalars.append(last)
			}

			return str
		}

		var data = Data()

		for type in reverseMap.keys.sorted() {
			data.append(contentsOf: type.utf8)
			data.append(contentsOf: reverseMap[type]!.utf8)
		}

		return data
	}

	static func data(compression: CompressionAlgorithm = .none, includeCRC: Bool = true) throws -> Data {
		var outputData = Data()

		var data = self.characterMapData() + self.disallowedCharactersData() + self.ignoredCharactersData() + self.joiningTypesData()

		if let rawAlgorithm = compression.rawAlgorithm {
			let capacity = 100_000
			let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)

			let compressed = try data.withUnsafeBytes { (rawBuffer) -> Data? in
				let bound = rawBuffer.bindMemory(to: UInt8.self)
				let encodedCount = compression_encode_buffer(destinationBuffer, capacity, bound.baseAddress!, rawBuffer.count, nil, rawAlgorithm)

				if encodedCount == 0 {
					throw UTS46Error.compressionError
				}

				return Data(bytes: destinationBuffer, count: encodedCount)
			}

			if compressed != nil {
				data = compressed!
			}
		}

		let header = Header(compression: compression, hasCRC: includeCRC)
		outputData.append(contentsOf: header.rawValue)

		if includeCRC {
			var crc = data.crc32.littleEndian
			let crcData = Data(bytes: &crc, count: MemoryLayout.stride(ofValue: crc))
			outputData.append(crcData)
		}

		outputData.append(data)

		return outputData
	}

	static func write(to fileHandle: FileHandle, compression: CompressionAlgorithm = .none) throws {
		let data = try self.data(compression: compression)

		if #available(macOS 10.15, iOS 13.0, *) {
			try fileHandle.write(contentsOf: data)
		} else {
			fileHandle.write(data)
		}
	}

	static func write(to url: URL, compression: CompressionAlgorithm = .none) throws {
		let data = try self.data(compression: compression)
		try data.write(to: url)
	}

}

extension UInt32 {

	var utf8: [UInt8] {
		var result = [UInt8]()
		UTF8.encode(UnicodeScalar(self)!) { result.append($0) }
		return result
	}

}
