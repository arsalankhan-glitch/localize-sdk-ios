import Foundation

/// Resolution order:
/// 1. API response (stored in cache)
/// 2. Cached API data
/// 3. Local bundled keys
///
/// API data always overwrites cache. Local keys are fallback only when
/// API/cache are unavailable.
public enum LocalizeResolver {
    /// Resolve which store to use. Prefer apiOrCache over local.
    public static func resolve(apiOrCache: LocalizeStore?, local: LocalizeStore?) -> LocalizeStore {
        if let api = apiOrCache, !api.isEmpty {
            return api
        }
        if let loc = local, !loc.isEmpty {
            return loc
        }
        return apiOrCache ?? local ?? LocalizeStore()
    }
}
