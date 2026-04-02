import XCTest
@testable import LocalizeSDK

final class ResolverTests: XCTestCase {
    func testApiOrCacheWins() {
        let api = LocalizeStore(simple: ["en": ["k": "from-api"]], plural: [:])
        let local = LocalizeStore(simple: ["en": ["k": "from-local"]], plural: [:])
        let result = LocalizeResolver.resolve(apiOrCache: api, local: local)
        XCTAssertEqual(result.simple["en"]?["k"], "from-api")
    }

    func testLocalFallbackWhenApiEmpty() {
        let local = LocalizeStore(simple: ["en": ["k": "from-local"]], plural: [:])
        let result = LocalizeResolver.resolve(apiOrCache: nil, local: local)
        XCTAssertEqual(result.simple["en"]?["k"], "from-local")
    }

    func testBothEmpty() {
        let result = LocalizeResolver.resolve(apiOrCache: nil, local: nil)
        XCTAssertTrue(result.isEmpty)
    }
}
