# Localiq SDK Example App

A sample iOS app to exercise the Localiq SDK and verify all scenarios.

## Open & Run

```bash
open Example/LocalizeSDKExample/LocalizeSDKExample.xcodeproj
```

Select a simulator or device and run (⌘R).

## Test Scenarios

| Scenario | Description | Expected |
|----------|-------------|----------|
| **Bundle-only keys** | `from_bundle_only`, `bundle_key` exist only in `Localizable.strings` | Resolved from bundle (native fallback) |
| **Simple strings** | `welcome` in bundle; if API has it, API wins | Bundle or API translation |
| **Interpolated** | `greeting` with `%@` placeholder | "Hello, User (from bundle)" |
| **Plurals** | `items_count` from `Localizable.stringsdict` | "No items", "1 item", "5 items" per locale |
| **Missing key** | `nonexistent_key_xyz` | Returns key as-is |
| **Locale switch** | English / Arabic buttons | All strings update per locale |
| **Refresh** | Refresh from API | Uses API data if available; bundle fallback when offline |

## Localization Files

- `en.lproj/Localizable.strings` – English simple strings
- `ar.lproj/Localizable.strings` – Arabic simple strings
- `en.lproj/Localizable.stringsdict` – English plurals
- `ar.lproj/Localizable.stringsdict` – Arabic plurals

## API Key

The app reads the key from the `LOCALIZE_EXAMPLE_API_KEY` environment variable. In Xcode, open **Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables** and add `LOCALIZE_EXAMPLE_API_KEY` with your project's key. Don't commit the key: Xcode stores this in your user scheme, which is ignored by git.

Without a key, or with no network, the SDK falls back to the bundled strings.
