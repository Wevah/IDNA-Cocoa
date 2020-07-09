//
//  UTS46+Conversion.swift
//  icumap2code
//
//  Created by Nate Weaver on 2020-05-08.
//

import Foundation
import Compression

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
			defer { _ = scanner.shimScanUpToCharacters(from: .newlines) }

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
			defer { _ = scanner.shimScanUpToCharacters(from: .newlines) }

			guard let range = scanner.scanHexRange() else { continue }

			guard scanner.shimScanString(";") != nil else { continue }

			guard let joiningType = scanner.shimScanCharacters(from: joiningTypeCharacters),
				joiningType.count == 1 else { continue }

			for codepoint in range {
				joiningTypes[UInt32(codepoint)] = JoiningType(rawValue: joiningType.first!)!
			}
		}
	}

	private static func characterMapData() -> Data {
		var data = Data()

		data.append(Marker.characterMap)

		for key in characterMap.keys.sorted() {
			data.append(contentsOf: key.utf8)

			let value = characterMap[key]!
			data.append(contentsOf: value.utf8)
			data.append(Marker.sequenceTerminator)
		}

		return data
	}

	private static func disallowedCharactersData() -> Data {
		return [Marker.disallowedCharacters] + disallowedCharacters.rangeStringData()
	}

	private static func ignoredCharactersData() -> Data {
		return [Marker.ignoredCharacters] + ignoredCharacters.rangeStringData()
	}

	private static func joiningTypesData() -> Data {
		var reverseMap: [Character: String] = ["C": "", "D": "", "L": "", "R": "", "T": ""]

		for (codepoint, joiningType) in joiningTypes {
			reverseMap[joiningType.rawValue]?.unicodeScalars.append(UnicodeScalar(codepoint)!)
		}

		reverseMap = reverseMap.mapValues {
			var str = ""
			var firstScalar: UnicodeScalar?
			var lastScalar: UnicodeScalar?

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

		data.append(Marker.joiningTypes)

		for type in reverseMap.keys.sorted() {
			data.append(contentsOf: type.utf8)
			data.append(contentsOf: reverseMap[type]!.utf8)
		}

		return data
	}

	static func data(compression: CompressionAlgorithm = .none, includeCRC: Bool = true) throws -> Data {
		var outputData = Data()

		var data = Data()
		data.append(self.characterMapData())
		data.append(self.disallowedCharactersData())
		data.append(self.ignoredCharactersData())
		data.append(self.joiningTypesData())

		if let rawAlgorithm = compression.rawAlgorithm {
			let capacity = 131_072 // 128 KB
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

		let header = Header(compression: compression, crc: includeCRC ? data.crc32 : nil)
		outputData.append(contentsOf: header.rawValue)

		outputData.append(data)

		return outputData
	}

}

extension UTS46 {

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
