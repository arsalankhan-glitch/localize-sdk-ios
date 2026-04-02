import Foundation

/// Internal SDK implementation. Use LocalizeSDK for the public API.
public final class LocalizeSDKImpl: @unchecked Sendable {
    private let config: LocalizeConfig
    private let fetcher: LocalizeFetcherProtocol
    private let cache: LocalizeCacheProtocol
    private let localLoader: LocalBundleLoader

    private var store: LocalizeStore = LocalizeStore()
    private var initialized = false
    private var fetchInProgress = false
    private let lock = NSLock()

    public var locale: String = "en"

    public init(
        config: LocalizeConfig,
        fetcher: LocalizeFetcherProtocol? = nil,
        cache: LocalizeCacheProtocol? = nil,
        localLoader: LocalBundleLoader? = nil
    ) {
        self.config = config
        self.fetcher = fetcher ?? URLSessionLocalizeFetcher(config: config)
        self.cache = cache ?? FileLocalizeCache(config: config)
        self.localLoader = localLoader ?? defaultLocalLoader(
            bundle: config.bundle,
            tableName: config.tableName
        )
    }

    public func initStore() async {
        lock.lock()
        if initialized {
            lock.unlock()
            return
        }
        initialized = true
        lock.unlock()

        if let fetched = await fetcher.fetch() {
            await cache.save(fetched)
            store = extractLocale(from: fetched, locale: locale)
            DispatchQueue.main.async { [weak self] in
                self?.config.onKeysUpdated?()
            }
            return
        }
        let cached = await cache.load(locale: locale)
        let local = await localLoader()
        store = LocalizeResolver.resolve(apiOrCache: cached, local: local)
    }

    private func extractLocale(from full: LocalizeStore, locale: String) -> LocalizeStore {
        var simple: [String: [String: String]] = [:]
        var plural: [String: [String: [String: String]]] = [:]
        if let s = full.simple[locale] { simple[locale] = s }
        if let p = full.plural[locale] { plural[locale] = p }
        if let fallback = config.fallbackLocale, fallback != locale {
            if let s = full.simple[fallback] { simple[fallback] = s }
            if let p = full.plural[fallback] { plural[fallback] = p }
        }
        return LocalizeStore(simple: simple, plural: plural)
    }

    public func setLocaleTo(_ newLocale: String) {
        locale = newLocale
        Task {
            if let loaded = await cache.load(locale: newLocale) {
                store = loaded
            } else if let local = await localLoader() {
                // Cache has no data for new locale; merge from bundle (e.g. API returned only one locale)
                var newSimple = store.simple
                var newPlural = store.plural
                if let s = local.simple[newLocale] { newSimple[newLocale] = s }
                if let p = local.plural[newLocale] { newPlural[newLocale] = p }
                store = LocalizeStore(simple: newSimple, plural: newPlural)
            }
            DispatchQueue.main.async { [weak self] in
                self?.config.onKeysUpdated?()
            }
        }
    }

    public func refresh() {
        lock.lock()
        if fetchInProgress {
            lock.unlock()
            return
        }
        fetchInProgress = true
        lock.unlock()

        Task {
            await performRefresh()
        }
    }

    private func performRefresh() async {
        defer {
            lock.lock()
            fetchInProgress = false
            lock.unlock()
            DispatchQueue.main.async { [weak self] in
                self?.config.onKeysUpdated?()
            }
        }

        guard let fetched = await fetcher.fetch() else { return }
        await cache.save(fetched)
        store = extractLocale(from: fetched, locale: locale)
    }

    public func getString(_ key: String, args: [Any]? = nil) -> String {
        var value = store.simple[locale]?[key]
        if value == nil, let fallback = config.fallbackLocale {
            value = store.simple[fallback]?[key]
        }
        if let v = value {
            return interpolate(template: v, args: args ?? [])
        }
        let native = stringFromBundle(forKey: key, locale: locale)
        guard native != key else { return key }
        return interpolate(template: native, args: args ?? [])
    }

    public func getPlural(_ key: String, count: Int) -> String {
        let form = selectPluralForm(locale: locale, count: count)
        var pluralMap = store.plural[locale]?[key]
        if pluralMap == nil, let fallback = config.fallbackLocale {
            pluralMap = store.plural[fallback]?[key]
        }
        if let map = pluralMap {
            let value = map[form] ?? map["other"] ?? map.values.first
            if let v = value {
                return interpolate(template: v, args: [count])
            }
        }
        let native = stringFromBundle(forKey: key, locale: locale)
        guard native != key else { return key }
        return interpolate(template: native, args: [count])
    }

    /// Bundle fallback using SDK locale (not app/device language).
    private func stringFromBundle(forKey key: String, locale: String) -> String {
        let bundle = config.bundle
        let table = config.tableName

        // Try locale-specific bundle (e.g. ar.lproj) so we get the correct translation
        if let lprojPath = bundle.path(forResource: locale, ofType: "lproj"),
           let localeBundle = Bundle(path: lprojPath) {
            let s = localeBundle.localizedString(forKey: key, value: key, table: table)
            if s != key { return s }
        }

        // Try fallback locale
        if let fallback = config.fallbackLocale, fallback != locale,
           let lprojPath = bundle.path(forResource: fallback, ofType: "lproj"),
           let localeBundle = Bundle(path: lprojPath) {
            let s = localeBundle.localizedString(forKey: key, value: key, table: table)
            if s != key { return s }
        }

        // Last resort: main bundle (uses app/device language)
        return bundle.localizedString(forKey: key, value: key, table: table)
    }

    private func interpolate(template: String, args: [Any]) -> String {
        guard !args.isEmpty else { return template }
        var result = template
        var idx = 0
        let pattern = #"%[sd@]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return template }
        var range = NSRange(result.startIndex..., in: result)
        var match = regex.firstMatch(in: result, range: range)
        while let m = match, idx < args.count, let r = Range(m.range, in: result) {
            result.replaceSubrange(r, with: String(describing: args[idx]))
            idx += 1
            range = NSRange(result.startIndex..., in: result)
            match = regex.firstMatch(in: result, range: range)
        }
        return result
    }
}
