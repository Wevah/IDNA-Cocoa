//
//  main.swift
//  icumap2code
//
//  Created by Nate Weaver on 2020-03-27.
//

import Foundation

if CommandLine.arguments.count < 2 {
	exit(EXIT_FAILURE)
}

enum Language {
	case swift
	case objc
}

let language = Language.swift

let file = URL(fileURLWithPath: CommandLine.arguments[1])

guard let text = try? String(contentsOf: file) else { exit(EXIT_FAILURE) }

var characterMapString = "\tstatic let characterMap: [UInt32: [UInt32]] = [\n"
var disallowedCharactersString = "\tstatic let disallowedCharacters: [ClosedRange<UInt32>] = [\n"

let scanner = Scanner(string: text)

while !scanner.isAtEnd {
	guard let fromStart = scanner.scanInt64(representation: .hexadecimal) else {
		let _ = scanner.scanUpToString("\n")
		continue
	}

	var fromEnd = fromStart

	if scanner.scanString("..") != nil {
		guard let temp = scanner.scanInt64(representation: .hexadecimal) else {
			let _ = scanner.scanUpToString("\n")
			continue
		}

		fromEnd = temp
	}

	guard scanner.scanString(">") != nil else {
		let _ = scanner.scanUpToString("\n")
		continue
	}

	var to = Array<Int64>()

	var isDisallowed = false

	while let scanned = scanner.scanInt64(representation: .hexadecimal) {
		if scanned == 0xFFFD {
			isDisallowed = true
			break
		}

		to.append(scanned)
	}

	let comment: String

	if scanner.scanString("#") != nil {
		comment = scanner.scanUpToString("\n") ?? ""
	} else {
		comment = ""
	}

	switch language {
		case .swift:
			if !isDisallowed {
				let mappedTo = to.map {
					return "0x\(String(format: "%X", $0))"
				}

				for codepoint in fromStart...fromEnd {
					let fromString = String(format: "%X", codepoint)
					characterMapString += "\t\t0x\(fromString): [\(mappedTo.joined(separator: ", "))], // \(comment)\n"
				}
			} else {
				let rangeStr = "\t\t0x\(String(format: "%X", fromStart))...0x\(String(format: "%X", fromEnd))"

				disallowedCharactersString += "\(rangeStr), // \(comment)\n"
			}

		case .objc:
			let mappedTo = to.map {
				return "@(0x\(String(format: "%X", $0)))"
			}

			characterMapString += "\t@(0x\(String(format: "%X", fromStart))): @[\(mappedTo.joined(separator: ", "))], // \(comment)\n"

	}
}


switch language {
	case .swift:
		characterMapString += "\t]"
		disallowedCharactersString += "\t]"

		print("enum UTS46 {\n")
		print(characterMapString)
		print()
		print(disallowedCharactersString)
		print("\n}")
	case .objc:
		print("}")
}
