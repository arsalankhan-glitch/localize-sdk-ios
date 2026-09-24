import Foundation

/// Public API for the Localize iOS SDK.
///
/// Usage:
/// ```swift
/// await LocalizeSDK.configure(
///     apiKey: "pk_xxx",
///     onKeysUpdated: { reloadUI() },
///     fallbackLocale: "en"
/// )
/// // In view:
/// Text(LocalizeSDK.getString("welcome_message"))
/// Text(LocalizeSDK.getString("greeting", args: ["John"]))
/// Text(LocalizeSDK.getPlural("items_count", count: 5))
/// ```
public enum LocalizeSDK {
    private static var _instance: LocalizeSDKImpl?
    private static let lock = NSLock()

    /// Configure the SDK. Call once at app startup.
    public static func configure(
        apiKey: String,
        platform: String = "ios",
        baseUrl: String? = nil,
        onKeysUpdated: (() -> Void)? = nil,
        fallbackLocale: String? = nil,
        timeoutSeconds: Int = 10,
        localLoader: LocalBundleLoader? = nil,
        enableLogging: Bool = true,
        tableName: String = "Localizable",
        bundle: Bundle = .main
    ) async {
        let config = LocalizeConfig(
            apiKey: apiKey,
            platform: platform,
            baseUrl: baseUrl ?? "https://localize-api.adres.ae",
            onKeysUpdated: onKeysUpdated,
            fallbackLocale: fallbackLocale,
            timeoutSeconds: timeoutSeconds,
            enableLogging: enableLogging,
            tableName: tableName,
            bundle: bundle
        )
        let impl = LocalizeSDKImpl(config: config, localLoader: localLoader)
        lock.lock()
        _instance = impl
        lock.unlock()
        await impl.initStore()
    }

    /// Set the current locale. Loads from cache in background; onKeysUpdated when done.
    public static func setLocale(_ value: String) {
        lock.lock()
        _instance?.setLocaleTo(value)
        lock.unlock()
    }

    /// Get the current locale.
    public static var locale: String {
        lock.lock()
        let v = _instance?.locale ?? "en"
        lock.unlock()
        return v
    }

    /// Refresh keys from API. Runs in background. Invokes onKeysUpdated when done.
    public static func refresh() {
        lock.lock()
        _instance?.refresh()
        lock.unlock()
    }

    /// Get a simple string.
    public static func getString(_ key: String, args: [Any]? = nil) -> String {
        lock.lock()
        let result = _instance?.getString(key, args: args) ?? key
        lock.unlock()
        return result
    }

    /// Get a plural string.
    public static func getPlural(_ key: String, count: Int) -> String {
        lock.lock()
        let result = _instance?.getPlural(key, count: count) ?? key
        lock.unlock()
        return result
    }

    /// Check if SDK is configured.
    public static var isConfigured: Bool {
        lock.lock()
        let v = _instance != nil
        lock.unlock()
        return v
    }

    /// Reset instance. For testing only.
    public static func resetForTesting() {
        lock.lock()
        _instance = nil
        lock.unlock()
    }
}
