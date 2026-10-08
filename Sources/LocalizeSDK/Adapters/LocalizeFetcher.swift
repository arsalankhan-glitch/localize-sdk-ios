import Foundation

/// Protocol for fetching localization data from the export endpoint.
public protocol LocalizeFetcherProtocol: Sendable {
    func fetch() async -> LocalizeStore?
}

/// Fetches localization data from GET /sdk/export.
public final class URLSessionLocalizeFetcher: LocalizeFetcherProtocol {
    private let config: LocalizeConfig
    private let session: URLSession

    public init(config: LocalizeConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    private var exportUrl: String {
        "\(config.baseUrl)/sdk/export?platform=\(config.platform.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.platform)"
    }

    private var headers: [String: String] {
        ["X-API-Key": config.apiKey]
    }

    private var headersForLog: [String: String] {
        ["X-API-Key": config.apiKey.isEmpty ? "" : "***"]
    }

    public func fetch() async -> LocalizeStore? {
        logRequest()
        guard let url = URL(string: exportUrl) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.timeoutInterval = TimeInterval(config.timeoutSeconds)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            logResponse(statusCode: http.statusCode, body: data)
            return parseResponse(statusCode: http.statusCode, data: data)
        } catch {
            logError(error)
            return nil
        }
    }

    private func parseResponse(statusCode: Int, data: Data) -> LocalizeStore? {
        if statusCode == 401 || statusCode == 403 || statusCode == 404 { return nil }
        if statusCode >= 500 { return nil }
        if statusCode != 200 { return nil }

        if data.isEmpty {
            return LocalizeStore()
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let store = parseStore(from: json) else {
            return nil
        }
        return store
    }

    private func parseStore(from json: [String: Any]) -> LocalizeStore? {
        guard let languages = json["languages"] as? [String: [String: Any]] else {
            return nil
        }
        var simple: [String: [String: String]] = [:]
        var plural: [String: [String: [String: String]]] = [:]

        for (locale, langData) in languages {
            simple[locale] = (langData["simple"] as? [String: String]) ?? [:]
            var pluralInner: [String: [String: String]] = [:]
            if let rawPlural = langData["plural"] as? [String: Any] {
                for (key, value) in rawPlural {
                    guard let forms = value as? [String: Any] else { continue }
                    let mapped = forms.compactMapValues { $0 as? String }
                    if !mapped.isEmpty { pluralInner[key] = mapped }
                }
            }
            plural[locale] = pluralInner
        }
        return LocalizeStore(simple: simple, plural: plural)
    }

    private func logRequest() {
        guard config.enableLogging else { return }
        print("[LocalizeSDK] GET \(exportUrl) Headers: \(headersForLog)")
    }

    private func logResponse(statusCode: Int, body: Data) {
        guard config.enableLogging else { return }
        let bodyStr = String(data: body, encoding: .utf8) ?? ""
        print("[LocalizeSDK] Status: \(statusCode) Response: \(bodyStr.prefix(200))...")
    }

    private func logError(_ error: Error) {
        guard config.enableLogging else { return }
        print("[LocalizeSDK] Error: \(error)")
    }
}
