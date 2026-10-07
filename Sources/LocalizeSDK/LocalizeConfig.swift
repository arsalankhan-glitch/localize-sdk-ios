import Foundation

/// Configuration for the Localize SDK.
public struct LocalizeConfig {
    /// Project API key for authenticating with the export endpoint.
    public let apiKey: String

    /// Platform identifier (ios, android, web, other, flutter).
    public let platform: String

    /// Base URL for the API. Encapsulated in SDK; defaults to production.
    public let baseUrl: String

    /// Callback invoked when refresh() completes (success or failure).
    public let onKeysUpdated: (() -> Void)?

    /// Fallback locale when translation is missing for current locale.
    public let fallbackLocale: String?

    /// Request timeout in seconds. Default 10.
    public let timeoutSeconds: Int

    /// When true, the SDK prints request/response to debug. Default true.
    public let enableLogging: Bool

    /// Table name for .strings/.stringsdict (e.g. "Localizable" or "Custom").
    /// Default "Localizable" maps to Localizable.strings and Localizable.stringsdict.
    public let tableName: String

    /// Bundle to load localizations from. Default .main.
    public let bundle: Bundle

    public init(
        apiKey: String,
        platform: String = "ios",
        baseUrl: String = "https://localize-api.adres.ae",
        onKeysUpdated: (() -> Void)? = nil,
        fallbackLocale: String? = nil,
        timeoutSeconds: Int = 10,
        enableLogging: Bool = true,
        tableName: String = "Localizable",
        bundle: Bundle = .main
    ) {
        self.apiKey = apiKey
        self.platform = platform
        self.baseUrl = baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.onKeysUpdated = onKeysUpdated
        self.fallbackLocale = fallbackLocale
        self.timeoutSeconds = timeoutSeconds
        self.enableLogging = enableLogging
        self.tableName = tableName
        self.bundle = bundle
    }
}
