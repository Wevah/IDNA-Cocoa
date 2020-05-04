//
//  main.swift
//  icumap2code
//
//  Created by Nate Weaver on 2020-03-27.
//

import Foundation
import ArgumentParser
import Compression
import Darwin

/// Output file format. Codepoints are stored UTF-8-encoded.
///
/// All multibyte integers are little-endian.
///
/// Header:
///
///     +--------------+---------+---------+---------+
///     | 6 bytes      | 1 byte  | 1 byte  | 4 bytes |
///     +--------------+---------+---------+---------+
/// 	| magic number | version | flags   | crc32   |
///     +--------------+---------+---------+---------+
///
/// - `magic number`: `"UTS#46"` (`0x55 0x54 0x53 0x23 0x34 0x36`).
/// - `version`: format version (1 byte; currently `0x01`).
/// - `flags`: Bitfield:
///
///       +-----+-----+-----+-----+-----+-----+-----+-----+
///       |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
///       +-----+-----+-----+-----+-----+-----+-----+-----+
///       | currently unused      | crc | compression     |
///       +-----+-----+-----+-----+-----+-----+-----+-----+
///
///     - `crc`: Contains a CRC32 of the data after the header.
///     - `compression`: compression mode of the data.
///       Currently identical to NSData's compression constants + 1:
///       0 = no compression, 1 = LZFSE, etc.
///
/// - `crc32`: CRC32 of the (possibly compressed) data. Implementations can skip
///   parsing this unless data integrity is an issue.
///
/// Data is a collection of data blocks of the format
///
///     [marker][section data] ...
///
/// Section data formats:
///
///	If marker is `characterMap`:
///
///	    [codepoint][mapped-codepoint ...][null] ...
///
///	If marker is `disallowedCharacters` or `ignoredCharacters`:
///
///	    [codepoint-range] ...
///
///	If marker is `joiningTypes`:
///
///		[type][[codepoint-range] ...]
///
///	where `type` is one of `C`, `D`, `L`, `R`, or `T`.
///
///	`codepoint-range`: two codepoints, marking the first and last codepoints of a
///	closed range. Single-codepoint ranges have the same start and end codepoint.
///
struct ICUMap2Code: ParsableCommand {
	static let configuration = CommandConfiguration(commandName: "icumap2code", abstract: "Convert UTS#46 and joiner type map files to a compact binary format.")

	@Option(name: [.customLong("compress"), .short], default: CompressionAlgorithm.none, help: ArgumentHelp("Output compression mode.", discussion: "Default is uncompressed. Supported values are 'lzfse', 'lz4', 'lzma', and 'zlib'.", valueName: "mode"))
	var compression: CompressionAlgorithm

	@Flag(name: .shortAndLong, help: "Verbose output (on STDERR).")
	var verbose: Bool

	/// ucs46.txt
	@Option(name: [.customLong("uts46"), .short], help: ArgumentHelp("uts46.txt input file.", valueName: "file"))
	var uts46File: String?

	/// DerivedJoiningType.txt
	@Option(name: [.customLong("joiners"), .short], help: ArgumentHelp("Joiner type input file.", valueName: "file"))
	var joinersFile: String?

	@Option(name: [.customLong("output"), .short], help: ArgumentHelp("The output file.", discussion: "If no file is specified, outputs to stdout.", valueName: "file"))
	var outputFile: String?

	enum Marker {
		static let characterMap = UInt8.max
		static let ignoredCharacters = UInt8.max - 1
		static let disallowedCharacters = UInt8.max - 2
		static let joiningTypes = UInt8.max - 3
		static let sequenceTerminator: UInt8 = 0
	}

	/// Identical values to `NSData.CompressionAlgorithm + 1`.
	enum CompressionAlgorithm: UInt8 {
		case none = 0
		case lzfse = 1
		case lz4 = 2
		case lzma = 3
		case zlib = 4
	}

	private struct Header: RawRepresentable, CustomDebugStringConvertible {
		typealias RawValue = [UInt8]

		var rawValue: [UInt8] {
			return Self.signature + [UInt8(0), version, flags.rawValue]
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

			version = rawValue[6]
			flags = Flags(rawValue: rawValue[7])
		}

		init(compression: CompressionAlgorithm = .none, hasCRC: Bool = false) {
			self.version = 1
			self.flags = Flags(compression: compression, hasCRC: hasCRC)
		}

		var debugDescription: String { "has CRC: \(hasCRC); compression: \(String(describing: compression))" }
	}


	func run() throws {

		var mapData = Data()

		if let path = uts46File {
			try mapData.append(self.convertICU46Map(from: path))
		}

		if let path = joinersFile {
			try mapData.append(self.convertDerivedJoiningType(from: path))
		}

		if compression != .none {
			let nsDataCompression = NSData.CompressionAlgorithm(rawValue: Int(compression.rawValue) - 1)!
			mapData = try (mapData as NSData).compressed(using: nsDataCompression) as Data
		}

		var outputData = Data()
		outputData.reserveCapacity(8 + 4 + mapData.count)
		let header = Header(compression: compression, hasCRC: true)
		outputData.append(contentsOf: header.rawValue)

		var crc = mapData.crc32.littleEndian
		let crcData = Data(bytes: &crc, count: MemoryLayout.stride(ofValue: crc))
		outputData.append(crcData)
		outputData.append(mapData)

		if let outputFile = outputFile {
			let url = URL.init(fileURLWithPath: outputFile)
			try outputData.write(to: url)
		} else {
			FileHandle.standardOutput.write(outputData)
		}
	}
}

extension Scanner {

	/// Scans a range of the form `hex[..hex]`.
	func scanHexRange() -> ClosedRange<Int>? {
		guard let start = self.scanInt(representation: .hexadecimal) else { return nil }

		var end = start

		if self.scanString("..") != nil {
			guard let temp = self.scanInt(representation: .hexadecimal) else { return nil }

			end = temp
		}

		return start...end
	}
}

private extension ICUMap2Code {

	func convertICU46Map(from path: String) throws -> Data {
		var outputData = Data()

		guard let text = try? String(contentsOfFile: path) else {
			print("Couldn't read from '\(path)'")
			throw ExitCode(ENOENT)
		}

		var characterMap = [UInt32: String]()
		var ignoredCharacters = ""
		var disallowedCharacters = ""

		let scanner = Scanner(string: text)

		while !scanner.isAtEnd {
			defer { let _ = scanner.scanUpToCharacters(from: .newlines) }

			guard let range = scanner.scanHexRange() else { continue }

			guard scanner.scanString(">") != nil else {
				continue
			}

			var mapped = ""

			var isDisallowed = false

			while let scanned = scanner.scanInt(representation: .hexadecimal) {
				if scanned == 0xFFFD {
					isDisallowed = true
					break
				}

				mapped.unicodeScalars.append(UnicodeScalar(scanned)!)
			}

			let isIgnored = mapped.count == 0

			if isDisallowed {
				disallowedCharacters.unicodeScalars.append(UnicodeScalar(range.lowerBound)!)
				disallowedCharacters.unicodeScalars.append(UnicodeScalar(range.upperBound)!)
			} else if isIgnored {
				ignoredCharacters.unicodeScalars.append(UnicodeScalar(range.lowerBound)!)
				ignoredCharacters.unicodeScalars.append(UnicodeScalar(range.upperBound)!)
			} else {
				for codepoint in range {
					characterMap[UInt32(codepoint)] = mapped
				}
			}
		}

		outputData.append(contentsOf: [Marker.characterMap])

		for key in characterMap.keys.sorted() {
			outputData.append(contentsOf: key.utf8)

			let value = characterMap[key]!
			outputData.append(contentsOf: value.utf8)
			outputData.append(contentsOf: [0])
		}

		if verbose {
			fputs("Current output size: \(outputData.count)\n", stderr)
		}

		if ignoredCharacters.count != 0 && ignoredCharacters.unicodeScalars.count % 2 == 0 {
			outputData.append(contentsOf: [Marker.ignoredCharacters])
			outputData.append(contentsOf: ignoredCharacters.utf8)

			if verbose {
				fputs("Ignored bounds data size: \(ignoredCharacters.utf8.count)\n", stderr)
			}
		}

		if disallowedCharacters.count != 0 && disallowedCharacters.unicodeScalars.count % 2 == 0  {
			outputData.append(contentsOf: [Marker.disallowedCharacters])
			outputData.append(contentsOf: disallowedCharacters.utf8)

			if verbose {
				fputs("Disallowed bounds data size: \(disallowedCharacters.utf8.count)\n", stderr)
			}
		}

		return outputData

	}

	func convertDerivedJoiningType(from path: String) throws -> Data {
		var outputData = Data()

		guard let text = try? String(contentsOfFile: path) else {
			print("Couldn't read from '\(path)'")
			throw ExitCode(ENOENT)
		}

		let scanner = Scanner(string: text)

		var map: [Character: String] = ["C": "", "D": "", "L": "", "R": "", "T": ""]

		let joiningTypeCharacters = CharacterSet(charactersIn: "CDRLT")

		while !scanner.isAtEnd {
			defer { let _ = scanner.scanUpToCharacters(from: .newlines) }

			guard let range = scanner.scanHexRange() else { continue }

			guard let _ = scanner.scanString(";") else { continue }

			guard let joiningType = scanner.scanCharacters(from: joiningTypeCharacters),
				joiningType.count == 1 else { continue }

			map[joiningType.first!]?.unicodeScalars.append(UnicodeScalar(range.lowerBound)!)
			map[joiningType.first!]?.unicodeScalars.append(UnicodeScalar(range.upperBound)!)
		}

		outputData.append(contentsOf: [Marker.joiningTypes])

		for type in map.keys.sorted() {
			outputData.append(contentsOf: type.utf8)
			outputData.append(contentsOf: map[type]!.utf8)
		}

		return outputData
	}

}

extension ICUMap2Code.CompressionAlgorithm: ExpressibleByArgument {
	public init?(argument: String) {
		switch argument {
			case "lz4":
				self = .lz4
			case "zlib":
				self = .zlib
			case "lzfse":
				self = .lzfse
			case "lzma":
				self = .lzma
			default:
				return nil
		}
	}
}

extension UInt32 {

	var utf8: [UInt8] {
		let scalar = UnicodeScalar(self)!
		return [UInt8](scalar.utf8)
	}

}

ICUMap2Code.main()
