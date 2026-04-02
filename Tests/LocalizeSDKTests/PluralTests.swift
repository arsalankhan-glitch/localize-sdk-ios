import XCTest
@testable import LocalizeSDK

final class PluralTests: XCTestCase {
    func testDefaultPlural() {
        XCTAssertEqual(selectPluralForm(locale: "en", count: 1), "one")
        XCTAssertEqual(selectPluralForm(locale: "en", count: 5), "other")
    }

    func testArabicPlural() {
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 0), "zero")
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 1), "one")
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 2), "two")
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 5), "few")
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 15), "many")
        XCTAssertEqual(selectPluralForm(locale: "ar", count: 100), "other")
    }

    func testSlavicPlural() {
        XCTAssertEqual(selectPluralForm(locale: "ru", count: 1), "one")
        XCTAssertEqual(selectPluralForm(locale: "ru", count: 21), "one")
        XCTAssertEqual(selectPluralForm(locale: "ru", count: 2), "few")
        XCTAssertEqual(selectPluralForm(locale: "ru", count: 5), "many")
    }

    func testFrenchPlural() {
        XCTAssertEqual(selectPluralForm(locale: "fr", count: 0), "one")
        XCTAssertEqual(selectPluralForm(locale: "fr", count: 1), "one")
        XCTAssertEqual(selectPluralForm(locale: "fr", count: 2), "other")
    }
}
