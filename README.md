# Localize SDK for iOS

Swift SDK that fetches translations from the Localize API and falls back to bundled strings when offline. Requires iOS 13+ or macOS 10.15+.

Example app: [`Example/`](Example/). Set your API key as the `LOCALIZE_EXAMPLE_API_KEY` environment variable in the Run scheme; see the [example README](Example/README.md).

## Installation

Add the package via Swift Package Manager in Xcode:

1. **File → Add Package Dependencies…**
2. Enter `https://github.com/arsalankhan-glitch/localize-sdk-ios` and select the `LocalizeSDK` library.

Or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arsalankhan-glitch/localize-sdk-ios", from: "0.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["LocalizeSDK"])
]
```

## Setup

Call `configure` once at app startup, before the first frame renders:

```swift
import LocalizeSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await LocalizeSDK.configure(
                        apiKey: "pk_xxx",
                        fallbackLocale: "en",
                        onKeysUpdated: { /* reload UI */ }
                    )
                }
        }
    }
}
```

## Usage

```swift
// Simple string
let label = LocalizeSDK.getString("welcome_message")

// Interpolated string (%@ placeholders)
let greeting = LocalizeSDK.getString("greeting", args: ["John"])

// Plural
let count = LocalizeSDK.getPlural("items_count", count: 5)

// Switch locale
LocalizeSDK.setLocale("ar")

// Refresh from API
LocalizeSDK.refresh()
```

## Configuration options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apiKey` | `String` | — | Project API key (required) |
| `fallbackLocale` | `String?` | `nil` | Locale to use when key is missing |
| `tableName` | `String` | `"Localizable"` | `.strings`/`.stringsdict` table name |
| `bundle` | `Bundle` | `.main` | Bundle containing localization files |
| `timeoutSeconds` | `Int` | `10` | Network request timeout |
| `enableLogging` | `Bool` | `true` | Print debug logs |
| `onKeysUpdated` | `() -> Void` | `nil` | Called after each successful refresh |

## How it works

1. On `configure`, the SDK fetches all translations from the API (every locale) and caches them on disk.
2. If the fetch fails, the SDK uses the cached translations for the current locale.
3. If the API is unreachable, it falls back to the bundled `.strings`/`.stringsdict` files.
4. Call `refresh()` at any time to pull the latest translations in the background.
5. Call `setLocale("ar")` to switch locale. The SDK reads that locale from the cache, with no network request.

## License

[MIT](LICENSE)
