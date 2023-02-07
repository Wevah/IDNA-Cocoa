//
//  main.swift
//  icumap2code
//
//  Created by Nate Weaver on 2020-03-27.
//

import Foundation
import ArgumentParser

struct ICUMap2Code: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "icumap2code",
		abstract: "Convert UTS#46 and joiner type map files to a compact binary format.",
		version: "1.0 (v10)"
	)

	@Option(
		name: [.customLong("compress"), .short],
		help: ArgumentHelp(
			"Output compression mode.",
			discussion: "Default is uncompressed. Supported values are 'lzfse', 'lz4', 'lzma', and 'zlib'.",
			valueName: "mode"
		)
	)
	var compression: UTS46.CompressionAlgorithm = .none

	@Flag(name: .shortAndLong, help: "Verbose output (on STDERR).")
	var verbose: Bool = false

	/// ucs46.txt
	@Option(name: [.customLong("uts46"), .short], help: ArgumentHelp("uts46.txt input file.", valueName: "file"))
	var uts46File: String?

	/// DerivedJoiningType.txt
	@Option(name: [.customLong("joiners"), .short], help: ArgumentHelp("Joiner type input file.", valueName: "file"))
	var joinersFile: String?

	@Option(
		name: [.customLong("output"), .short],
		help: ArgumentHelp(
			"The output file.",
			discussion: "If no file is specified, outputs to stdout.",
			valueName: "file"
		)
	)
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
