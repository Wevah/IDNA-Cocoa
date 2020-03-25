//
//  PunycodeSwiftTests.swift
//  PunycodeSwiftTests
//
//  Created by Nate Weaver on 2020-03-18.
//

import XCTest

class PunycodeSwiftTests: XCTestCase {

	func testIDNAEncoding() {
		let dict = [
			"http://www.bücher.ch/":	"http://www.xn--bcher-kva.ch/",
			"президент":				"xn--d1abbgf6aiiy",
			"例え":						"xn--r8jz45g"
		]

		for (key, value) in dict {
			XCTAssertEqual(key.idnaEncoded, value)
		}
	}

	func testIDNDecoding() {
		let dict = [
			"http://www.xn--bcher-kva.ch/":	"http://www.bücher.ch/",
			"xn--d1abbgf6aiiy":				"президент",
			"xn--r8jz45g": 					"例え"
		]

		for (key, value) in dict {
			XCTAssertEqual(key.idnaDecoded, value)
		}
	}

	func testFullURLEncoding() {
		let dict = [
			"http://www.bücher.ch/":						"http://www.xn--bcher-kva.ch/",
			"http://www.bücher.ch/bücher":					"http://www.xn--bcher-kva.ch/b%C3%BCcher",
			"https://www.google.co.jp/webhp?foo#q=渋谷":		"https://www.google.co.jp/webhp?foo#q=%E6%B8%8B%E8%B0%B7",
			"https://www.google.co.jp/webhp?foo#q=%20渋谷":	"https://www.google.co.jp/webhp?foo#q=%20%E6%B8%8B%E8%B0%B7",
			"http://localhost:3000":						"http://localhost:3000",
			"http://localhost?fü":							"http://localhost?f%C3%BC"
		]

		for (key, value) in dict {
			XCTAssertEqual(key.encodedURLString, value)
		}
	}

	func testFullURLDecoding() {
		let dict = [
			"http://www.xn--bcher-kva.ch/":								"http://www.bücher.ch/",
			"http://www.xn--bcher-kva.ch/b%C3%BCcher":					"http://www.bücher.ch/bücher",
			"https://www.google.co.jp/webhp?foo#q=%E6%B8%8B%E8%B0%B7":	"https://www.google.co.jp/webhp?foo#q=渋谷",
			"http://localhost:3000":									"http://localhost:3000",
			"http://localhost?f%C3%BC":									"http://localhost?fü"
		]

		for (key, value) in dict {
			XCTAssertEqual(key.decodedURLString, value)
		}
	}

	func testConvenienceMethods() {
		XCTAssertEqual(URL(unicodeString: "http://www.bücher.ch/"), URL(string: "http://www.xn--bcher-kva.ch/"));
		XCTAssertEqual(URL(string:"http://www.xn--bcher-kva.ch/")!.decodedURLString, "http://www.bücher.ch/");
	}

	func testRelativeEncoding() {
		XCTAssertEqual("/bücher".encodedURLString, "/b%C3%BCcher")
		XCTAssertEqual("//bücher".encodedURLString, "//xn--bcher-kva")
		XCTAssertEqual("///bücher".encodedURLString, "///b%C3%BCcher")
	}
}
