import XCTest
@testable import LocalizeSDK

final class LocalizeSDKTests: XCTestCase {
    override func tearDown() {
        LocalizeSDK.resetForTesting()
        super.tearDown()
    }

    func testUnconfiguredReturnsKey() {
        XCTAssertEqual(LocalizeSDK.getString("any_key"), "any_key")
        XCTAssertEqual(LocalizeSDK.getPlural("items", count: 5), "items")
    }

    func testConfigureAndGetString() async {
        let store = LocalizeStore(
            simple: ["en": ["welcome": "Welcome!"]],
            plural: [:]
        )
        let config = LocalizeConfig(apiKey: "test", platform: "ios")
        let cache = MockCache(initialStore: store)
        let impl = LocalizeSDKImpl(config: config, cache: cache, localLoader: { nil })
        await impl.initStore()

        impl.locale = "en"
        XCTAssertEqual(impl.getString("welcome"), "Welcome!")
        XCTAssertEqual(impl.getString("missing"), "missing")
    }

    func testGetPlural() async {
        let store = LocalizeStore(
            simple: [:],
            plural: ["en": ["items": ["one": "1 item", "other": "%d items"]]]
        )
        let config = LocalizeConfig(apiKey: "test", platform: "ios")
        let cache = MockCache(initialStore: store)
        let impl = LocalizeSDKImpl(config: config, cache: cache, localLoader: { nil })
        await impl.initStore()

        impl.locale = "en"
        XCTAssertEqual(impl.getPlural("items", count: 1), "1 item")
        XCTAssertEqual(impl.getPlural("items", count: 5), "5 items")
    }

    func testInterpolation() async {
        let store = LocalizeStore(
            simple: ["en": ["greeting": "Hello, %s!"]],
            plural: [:]
        )
        let config = LocalizeConfig(apiKey: "test", platform: "ios")
        let cache = MockCache(initialStore: store)
        let impl = LocalizeSDKImpl(config: config, cache: cache, localLoader: { nil })
        await impl.initStore()

        impl.locale = "en"
        XCTAssertEqual(impl.getString("greeting", args: ["John"]), "Hello, John!")
    }
}

private final class MockCache: LocalizeCacheProtocol {
    private var store: LocalizeStore?

    init(initialStore: LocalizeStore?) {
        self.store = initialStore
    }

    func load(locale: String) async -> LocalizeStore? {
        store
    }

    func save(_ store: LocalizeStore) async {
        self.store = store
    }
}
