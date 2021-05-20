//
//  IDNATests.swift
//  IDNATests
//
//  Created by Nate Weaver on 2020-03-18.
//

#if !os(watchOS)
import XCTest
@testable import IDNA

class IDNATests: XCTestCase {

	func testIDNAEncoding() {
		let dict = [
			"http://www.bücher.ch/":	"http://www.xn--bcher-kva.ch/",
			"президент":				"xn--d1abbgf6aiiy",
			"例え":						"xn--r8jz45g",
			/* ltr */ "איגוד-האינטרנט.org.il": "xn----zhcbgfhe2aacg8fb5i.org.il"
		]

		for (key, value) in dict {
			XCTAssertEqual(key.idnaEncoded, value)
		}
	}

	func testIDNDecoding() {
		let dict = [
			"http://www.xn--bcher-kva.ch/":	"http://www.bücher.ch/",
			"xn--d1abbgf6aiiy":				"президент",
			"xn--r8jz45g": 					"例え",
			"xn----zhcbgfhe2aacg8fb5i.org.il": "איגוד-האינטרנט.org.il"
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
		XCTAssertEqual("//bücher/bücher".encodedURLString, "//xn--bcher-kva/b%C3%BCcher");
	}

	func testNormalizedEncoding() {
		// u + combining umlaut should convert to u-with-umlaut
		let utf8: [UInt8] = [0x75, 0xcc, 0x88]
		let str = String(bytes: utf8, encoding: .utf8)
		XCTAssertEqual(str?.idnaEncoded, "xn--tda")
	}

	func testInvalidCodepoints() {
		XCTAssertNil("a⒈com".idnaEncoded)
	}

	func testInvalidDecoding() {
		XCTAssertNil("xn--u-ccb.com".idnaDecoded)
		XCTAssertNil("xn--0.pt".idnaDecoded)
		XCTAssertNil("xn--a-ecp.ru".idnaDecoded)
	}

	func testCRC32() {
		let data = "foo".data(using: .utf8)!
		XCTAssertEqual(data.crc32, 0x8c736521)
	}

//	func testRangeStringData() {
//		let charset = CharacterSet(charactersIn: "abcdefgmwxyz")
//		let rangeData = charset.rangeStringData()
//		XCTAssertEqual(rangeData, "agmmwz".data(using: .utf8)!)
//	}

	func testEmptyFragment() {
		XCTAssertEqual("https://derailer.org/foo#".encodedURLString, "https://derailer.org/foo#")
	}

	func testEmptyQuery() {
		XCTAssertEqual("https://derailer.org/foo?".encodedURLString, "https://derailer.org/foo?")
	}

	func testEmptyHostWithQuery() {
		XCTAssertEqual("https://?".encodedURLString, "https://?")
	}

	func testNoSchemeButSlash() {
		XCTAssertEqual("foo/bar".encodedURLString, "foo/bar")
		XCTAssertEqual("foobar.com/".encodedURLString, "foobar.com/")
	}

	func testASCIIURL() {
		XCTAssertEqual(URL(unicodeString: "https://foobar.com/"), URL(string: "https://foobar.com/"))
	}

	func testUnicodePath() {
		XCTAssertEqual(URL(unicodeString: "https://foobar.com/bücher"), URL(string: "https://foobar.com/b%C3%BCcher"))
	}

	func testSpace() {
		XCTAssertEqual("https://foo.com/foo bar/".encodedURLString, "https://foo.com/foo%20bar/")
	}

	func testRelative() {
		let base = URL(string: "https://foo.com/")

		XCTAssertEqual(URL(unicodeString: "bar", relativeTo: base)?.absoluteString, "https://foo.com/bar")
		XCTAssertEqual(URL(unicodeString: "bär", relativeTo: base)?.absoluteString, "https://foo.com/b%C3%A4r")
		XCTAssertEqual(URL(unicodeString: "bär?baz#quux", relativeTo: base)?.absoluteString, "https://foo.com/b%C3%A4r?baz#quux")

		XCTAssertEqual(URL(unicodeString: "https://bär.com/", relativeTo: base)?.absoluteString, "https://xn--br-via.com/")

		XCTAssertEqual(URL(unicodeString: "/:", relativeTo: base)?.absoluteString, "https://foo.com/:")
		XCTAssertEqual(URL(unicodeString: ":/", relativeTo: base)?.absoluteString, "https://foo.com/")

	}

	func testMoreRelative() {
		let base = URL(string: "https://foo.com/")

		XCTAssertEqual(URL(unicodeString: "//bär/", relativeTo: base)?.absoluteString, "https://xn--br-via/")
	}

}
#endif
