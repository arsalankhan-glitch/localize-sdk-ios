import Foundation

/// In-memory storage structure for O(1) lookup.
/// simple: [Locale: [Key: String]]
/// plural: [Locale: [Key: [PluralForm: String]]]
public struct LocalizeStore {
    public let simple: [String: [String: String]]
    public let plural: [String: [String: [String: String]]]

    public init(
        simple: [String: [String: String]] = [:],
        plural: [String: [String: [String: String]]] = [:]
    ) {
        self.simple = simple
        self.plural = plural
    }

    public var isEmpty: Bool {
        simple.isEmpty && plural.isEmpty
    }

    /// Deep copy for immutability when replacing store.
    public func deepCopy() -> LocalizeStore {
        var newSimple: [String: [String: String]] = [:]
        for (k, v) in simple {
            newSimple[k] = v
        }
        var newPlural: [String: [String: [String: String]]] = [:]
        for (locale, keys) in plural {
            var inner: [String: [String: String]] = [:]
            for (key, forms) in keys {
                inner[key] = forms
            }
            newPlural[locale] = inner
        }
        return LocalizeStore(simple: newSimple, plural: newPlural)
    }
}
