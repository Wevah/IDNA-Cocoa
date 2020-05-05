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

	@Option(name: [.customLong("compress"), .short], default: UTS46.CompressionAlgorithm.none, help: ArgumentHelp("Output compression mode.", discussion: "Default is uncompressed. Supported values are 'lzfse', 'lz4', 'lzma', and 'zlib'.", valueName: "mode"))
	var compression: UTS46.CompressionAlgorithm

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


	func run() throws {
		if let path = uts46File {
			try UTS46.readCharacterMap(fromTextFile: URL(fileURLWithPath: path))
		}

		if let path = joinersFile {
			try UTS46.readJoinerTypes(fromTextFile: URL(fileURLWithPath: path))
		}

		if let outputFile = outputFile {
			let url = URL.init(fileURLWithPath: outputFile)
			try UTS46.write(to: url, compression: compression)
		} else {
			try UTS46.write(to: FileHandle.standardOutput, compression: compression)
		}
	}
}

extension UTS46.CompressionAlgorithm: ExpressibleByArgument {
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

ICUMap2Code.main()
