# Localize SDK Example App

A sample iOS app to exercise the Localize SDK and verify all scenarios.

## Open & Run

```bash
cd packages/ios_localize_sdk
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

The app uses `pk_demo_example`. With no network or invalid key, the SDK falls back to bundled strings. Configure a real API key to test API + bundle fallback together.
