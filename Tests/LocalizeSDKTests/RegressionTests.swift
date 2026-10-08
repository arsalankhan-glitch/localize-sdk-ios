import CryptoKit
import XCTest
@testable import LocalizeSDK

final class RegressionTests: XCTestCase {
    // MARK: - Plural parsing

    func testFetcherKeepsValidPluralsWhenOneEntryIsMalformed() async throws {
        StubURLProtocol.body = """
        {"languages": {"en": {
            "simple": {},
            "plural": {
                "items": {"one": "1 item", "other": "%d items"},
                "broken": "not a plural map"
            }
        }}}
        """
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [StubURLProtocol.self]
        let fetcher = URLSessionLocalizeFetcher(
            config: LocalizeConfig(apiKey: "test", enableLogging: false),
            session: URLSession(configuration: sessionConfig)
        )

        let fetched = await fetcher.fetch()
        let store = try XCTUnwrap(fetched)

        XCTAssertEqual(store.plural["en"]?["items"], ["one": "1 item", "other": "%d items"])
        XCTAssertNil(store.plural["en"]?["broken"])
    }

    func testCacheKeepsValidPluralsWhenOneEntryIsMalformed() async throws {
        let apiKey = "regression_\(UUID().uuidString)"
        let config = LocalizeConfig(apiKey: apiKey, enableLogging: false)
        let fileURL = try cacheFileURL(apiKey: apiKey, platform: config.platform, locale: "en")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let json = """
        {"locale": "en", "simple": {}, "plural": {
            "items": {"one": "1 item", "other": "%d items"},
            "broken": 42
        }}
        """
        try Data(json.utf8).write(to: fileURL)

        let loaded = await FileLocalizeCache(config: config).load(locale: "en")
        let store = try XCTUnwrap(loaded)

        XCTAssertEqual(store.plural["en"]?["items"], ["one": "1 item", "other": "%d items"])
        XCTAssertNil(store.plural["en"]?["broken"])
    }

    // MARK: - setLocale

    func testSetLocaleKeepsFallbackLocaleStrings() async {
        let updated = expectation(description: "onKeysUpdated after setLocale")
        updated.assertForOverFulfill = false
        let config = LocalizeConfig(
            apiKey: "test",
            onKeysUpdated: { updated.fulfill() },
            fallbackLocale: "en",
            enableLogging: false
        )
        let cache = PerLocaleCache(stores: [
            "en": LocalizeStore(
                simple: ["en": ["only_in_english": "English text"]],
                plural: ["en": ["items": ["one": "1 item", "other": "%d items"]]]
            ),
            "ar": LocalizeStore(simple: ["ar": ["welcome": "مرحبا"]], plural: [:]),
        ])
        let impl = LocalizeSDKImpl(config: config, fetcher: NoNetworkFetcher(), cache: cache, localLoader: { nil })
        await impl.initStore()

        impl.setLocaleTo("ar")
        await fulfillment(of: [updated], timeout: 2)

        XCTAssertEqual(impl.getString("welcome"), "مرحبا")
        XCTAssertEqual(impl.getString("only_in_english"), "English text")
        XCTAssertEqual(impl.getPlural("items", count: 3), "3 items")
    }

    // MARK: - Helpers

    /// Mirrors FileLocalizeCache's file naming: localize_<first 8 hex of SHA-256(apiKey)>_<platform>_<locale>.json
    private func cacheFileURL(apiKey: String, platform: String, locale: String) throws -> URL {
        let hash = SHA256.hash(data: Data(apiKey.utf8)).map { String(format: "%02x", $0) }.joined()
        let caches = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        return caches.appendingPathComponent("localize_\(hash.prefix(8))_\(platform)_\(locale).json")
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var body = ""

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct NoNetworkFetcher: LocalizeFetcherProtocol {
    func fetch() async -> LocalizeStore? { nil }
}

private final class PerLocaleCache: LocalizeCacheProtocol, @unchecked Sendable {
    private let stores: [String: LocalizeStore]

    init(stores: [String: LocalizeStore]) {
        self.stores = stores
    }

    func load(locale: String) async -> LocalizeStore? { stores[locale] }
    func save(_ store: LocalizeStore) async {}
}
