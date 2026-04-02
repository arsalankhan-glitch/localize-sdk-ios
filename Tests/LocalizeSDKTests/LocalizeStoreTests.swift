import XCTest
@testable import LocalizeSDK

final class LocalizeStoreTests: XCTestCase {
    func testEmptyStore() {
        let store = LocalizeStore()
        XCTAssertTrue(store.isEmpty)
        XCTAssertTrue(store.simple.isEmpty)
        XCTAssertTrue(store.plural.isEmpty)
    }

    func testNonEmptyStore() {
        let store = LocalizeStore(
            simple: ["en": ["welcome": "Welcome!"]],
            plural: [:]
        )
        XCTAssertFalse(store.isEmpty)
        XCTAssertEqual(store.simple["en"]?["welcome"], "Welcome!")
    }

    func testDeepCopy() {
        let store = LocalizeStore(
            simple: ["en": ["k": "v"]],
            plural: ["en": ["items": ["one": "1", "other": "many"]]]
        )
        let copy = store.deepCopy()
        XCTAssertEqual(copy.simple["en"]?["k"], "v")
        XCTAssertEqual(copy.plural["en"]?["items"]?["one"], "1")
    }
}
