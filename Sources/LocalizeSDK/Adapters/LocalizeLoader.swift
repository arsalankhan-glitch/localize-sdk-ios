import Foundation

/// Loader for local bundled keys (fallback when API/cache unavailable).
public typealias LocalBundleLoader = () async -> LocalizeStore?

/// Default loader: reads from platform .strings and .stringsdict files.
/// Uses configurable table name (default "Localizable").
public func defaultLocalLoader(
    bundle: Bundle = .main,
    tableName: String = "Localizable"
) -> LocalBundleLoader {
    { await loadFromBundle(bundle: bundle, tableName: tableName) }
}

/// Load from iOS .strings and .stringsdict using standard bundle paths.
private func loadFromBundle(bundle: Bundle, tableName: String) async -> LocalizeStore? {
    var simple: [String: [String: String]] = [:]
    var plural: [String: [String: [String: String]]] = [:]

    guard let lprojURLs = bundle.urls(forResourcesWithExtension: "lproj", subdirectory: nil) else {
        return LocalizeStore(simple: simple, plural: plural)
    }

    for lprojURL in lprojURLs {
        let locale = lprojURL.deletingPathExtension().lastPathComponent
        let stringsURL = lprojURL.appendingPathComponent("\(tableName).strings")
        let stringsdictURL = lprojURL.appendingPathComponent("\(tableName).stringsdict")

        if let s = parseStringsFile(url: stringsURL) {
            simple[locale] = s
        } else {
            simple[locale] = [:]
        }

        if let p = parseStringsdictFile(url: stringsdictURL) {
            plural[locale] = p
        } else {
            plural[locale] = [:]
        }
    }

    return LocalizeStore(simple: simple, plural: plural)
}

/// Parse .strings file: "key" = "value";
private func parseStringsFile(url: URL) -> [String: String]? {
    guard FileManager.default.fileExists(atPath: url.path),
          let content = try? String(contentsOf: url, encoding: .utf8) else {
        return nil
    }
    return parseStringsContent(content)
}

private func parseStringsContent(_ content: String) -> [String: String] {
    var result: [String: String] = [:]
    let pattern = #""([^"\\]*(?:\\.[^"\\]*)*)"\s*=\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*;"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
    let range = NSRange(content.startIndex..., in: content)
    regex.enumerateMatches(in: content, range: range) { match, _, _ in
        guard let m = match, m.numberOfRanges >= 3,
              let kRange = Range(m.range(at: 1), in: content),
              let vRange = Range(m.range(at: 2), in: content) else { return }
        let key = String(content[kRange]).unescapeStrings()
        let value = String(content[vRange]).unescapeStrings()
        result[key] = value
    }
    return result
}

/// Parse .stringsdict plist for plurals.
private func parseStringsdictFile(url: URL) -> [String: [String: String]]? {
    guard FileManager.default.fileExists(atPath: url.path),
          let plist = NSDictionary(contentsOf: url) as? [String: Any] else {
        return nil
    }
    return parseStringsdictContent(plist)
}

private func parseStringsdictContent(_ plist: [String: Any]) -> [String: [String: String]] {
    var result: [String: [String: String]] = [:]
    for (key, value) in plist {
        guard let dict = value as? [String: Any],
              let forms = extractPluralForms(from: dict) else { continue }
        result[key] = forms
    }
    return result
}

/// Extract plural forms (one, other, zero, etc.) from stringsdict variable dict.
private func extractPluralForms(from dict: [String: Any]) -> [String: String]? {
    for (_, v) in dict {
        guard let inner = v as? [String: Any] else { continue }
        if inner["NSStringFormatSpecTypeKey"] as? String == "NSStringPluralRuleType" {
            var forms: [String: String] = [:]
            for (k, val) in inner {
                guard ["one", "other", "zero", "two", "few", "many"].contains(k),
                      let s = val as? String else { continue }
                forms[k] = s
            }
            return forms.isEmpty ? nil : forms
        }
    }
    return nil
}

private extension String {
    func unescapeStrings() -> String {
        self.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}

/// Parse JSON string to LocalizeStore (optional; for custom loaders).
public func parseLocalBundleJson(_ jsonString: String) -> LocalizeStore? {
    guard let data = jsonString.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    return parseStore(from: json)
}

private func parseStore(from json: [String: Any]) -> LocalizeStore? {
    guard let languages = json["languages"] as? [String: [String: Any]] else {
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
