import XCTest
@testable import LocalizeSDK

final class LoaderTests: XCTestCase {
    func testDefaultLoaderReturnsStore() async {
        let loader = defaultLocalLoader(bundle: .main, tableName: "Localizable")
        let store = await loader()
        XCTAssertNotNil(store)
    }

    func testParseLocalBundleJsonStillWorks() {
        let json = """
        {"languages":{"en":{"simple":{"k":"v"},"plural":{}}}}
        """
        let store = parseLocalBundleJson(json)
        XCTAssertNotNil(store)
        XCTAssertEqual(store?.simple["en"]?["k"], "v")
    }
}
