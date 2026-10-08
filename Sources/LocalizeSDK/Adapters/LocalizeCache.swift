import Foundation
import CryptoKit

/// Protocol for disk cache of localization data.
public protocol LocalizeCacheProtocol: Sendable {
    func load(locale: String) async -> LocalizeStore?
    func save(_ store: LocalizeStore) async
}

/// Disk cache: one file per locale: {cachesDirectory}/localize_{hash}_{platform}_{locale}.json
public final class FileLocalizeCache: LocalizeCacheProtocol {
    private let config: LocalizeConfig
    private let fileManager: FileManager
    private let cachePrefix: String

    public init(config: LocalizeConfig, fileManager: FileManager = .default) {
        self.config = config
        self.fileManager = fileManager
        self.cachePrefix = "localize_\(Self.hashPrefix(config.apiKey))_\(config.platform)"
    }

    private static func hashPrefix(_ apiKey: String) -> String {
        let data = Data(apiKey.utf8)
        let hash = SHA256.hash(data: data)
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(8))
    }

    private var cachesDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private func cacheFileURL(for locale: String) -> URL? {
        cachesDirectory?.appendingPathComponent("\(cachePrefix)_\(locale).json")
    }

    private var legacyCacheFileURL: URL? {
        cachesDirectory?.appendingPathComponent("\(cachePrefix).json")
    }

    public func load(locale: String) async -> LocalizeStore? {
        let path = cacheFileURL(for: locale)?.path
        let legacyPath = legacyCacheFileURL?.path

        return await Task.detached(priority: .utility) {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                return Self.loadLocaleFile(path: path, locale: locale)
            }
            return Self.tryMigrateFromLegacy(legacyPath: legacyPath, locale: locale)
        }.value
    }

    private static func loadLocaleFile(path: String, locale: String) -> LocalizeStore? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            guard !data.isEmpty else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return parseLocaleFile(json: json, locale: locale)
        } catch {
            return nil
        }
    }

    private static func parseLocaleFile(json: [String: Any], locale: String) -> LocalizeStore? {
        let simpleRaw = json["simple"] as? [String: String] ?? [:]
        var pluralInner: [String: [String: String]] = [:]
        if let rawPlural = json["plural"] as? [String: Any] {
            for (key, value) in rawPlural {
                guard let forms = value as? [String: Any] else { continue }
                let mapped = forms.compactMapValues { $0 as? String }
                if !mapped.isEmpty { pluralInner[key] = mapped }
            }
        }
        return LocalizeStore(
            simple: [locale: simpleRaw],
            plural: [locale: pluralInner]
        )
    }

    private static func tryMigrateFromLegacy(legacyPath: String?, locale: String) -> LocalizeStore? {
        guard let path = legacyPath, FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        guard let full = parseLegacyStore(path: path) else { return nil }
        let dir = (path as NSString).deletingLastPathComponent
        let prefix = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        for loc in Set(full.simple.keys).union(full.plural.keys) {
            let json: [String: Any] = [
                "locale": loc,
                "simple": full.simple[loc] ?? [:],
                "plural": full.plural[loc] ?? [:],
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: json) else { continue }
            let newPath = (dir as NSString).appendingPathComponent("\(prefix)_\(loc).json")
            try? data.write(to: URL(fileURLWithPath: newPath))
        }
        try? FileManager.default.removeItem(atPath: path)
        let simple = full.simple[locale].map { [locale: $0] } ?? [:]
        let plural = full.plural[locale].map { [locale: $0] } ?? [:]
        return LocalizeStore(simple: simple, plural: plural)
    }

    private static func parseLegacyStore(path: String) -> LocalizeStore? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let languages = json["languages"] as? [String: [String: Any]] else {
            return nil
        }
        var simple: [String: [String: String]] = [:]
        var plural: [String: [String: [String: String]]] = [:]
        for (locale, langData) in languages {
            simple[locale] = (langData["simple"] as? [String: String]) ?? [:]
            let pluralRaw = langData["plural"] as? [String: [String: Any]] ?? [:]
            var pluralInner: [String: [String: String]] = [:]
            for (key, forms) in pluralRaw {
                pluralInner[key] = forms.compactMapValues { $0 as? String }
            }
            plural[locale] = pluralInner
        }
        return LocalizeStore(simple: simple, plural: plural)
    }

    public func save(_ store: LocalizeStore) async {
        guard let baseURL = cachesDirectory else { return }
        let allLocales = Set(store.simple.keys).union(store.plural.keys)
        let prefix = cachePrefix

        await Task.detached(priority: .utility) {
            for locale in allLocales {
                let json: [String: Any] = [
                    "locale": locale,
                    "simple": store.simple[locale] ?? [:],
                    "plural": store.plural[locale] ?? [:],
                ]
                guard let data = try? JSONSerialization.data(withJSONObject: json) else { continue }
                let url = baseURL.appendingPathComponent("\(prefix)_\(locale).json")
                try? data.write(to: url)
            }
        }.value
    }
}
