import SwiftUI
import LocalizeSDK

struct ContentView: View {
    @State private var refreshId = UUID()

    var body: some View {
        keysUpdatedListener
        .environment(\.layoutDirection,LocalizeSDK.locale == "ar" ? .rightToLeft:.leftToRight)
        .onReceive(NotificationCenter.default.publisher(for: .localizeKeysUpdated)) { _ in
            refreshId = UUID()
        }
    }

    private var keysUpdatedListener: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    bundleOnlySection
                    simpleSection
                    interpolatedSection
                    pluralSection
                    missingKeySection
                    actionsSection
                }
                .padding()
            }
            .navigationTitle(LocalizeSDK.getString("app_name"))
        }
        .id(refreshId)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Scenarios")
                .font(.headline)
            Text("Current locale: \(LocalizeSDK.locale)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bundle-only keys (never from API)

    private var bundleOnlySection: some View {
        scenarioCard(title: "Bundle-only keys", note: "Keys only in Localizable.strings, not from API") {
            VStack(alignment: .leading, spacing: 6) {
                row("from_bundle_only", LocalizeSDK.getString("from_bundle_only"))
                row("bundle_key", LocalizeSDK.getString("bundle_key"))
            }
        }
    }

    // MARK: - Simple strings (bundle or API)

    private var simpleSection: some View {
        scenarioCard(title: "Simple strings", note: "welcome: from bundle if API has no data") {
            row("app_name", LocalizeSDK.getString("app_name"))
            row("val95031_title_ios", LocalizeSDK.getString("val95031_title_ios"))
            row("total_pending_rent_for_remaining_period", LocalizeSDK.getString("total_pending_rent_for_remaining_period"))
            row("error_200027_ios", LocalizeSDK.getString("error_200027_ios"))
        }
    }

    // MARK: - Interpolated strings

    private var interpolatedSection: some View {
        scenarioCard(title: "Interpolated strings", note: "greeting with %@ placeholder") {
            row("greeting (args: [\"User\"])", LocalizeSDK.getString("greeting", args: ["User"]))
        }
    }

    // MARK: - Plurals

    private var pluralSection: some View {
        scenarioCard(title: "Plurals", note: "items_count with count argument") {
            VStack(alignment: .leading, spacing: 6) {
                row("count: 0", LocalizeSDK.getPlural("items_count", count: 0))
                row("count: 1", LocalizeSDK.getPlural("items_count", count: 1))
                row("count: 5", LocalizeSDK.getPlural("items_count", count: 5))
            }
        }
    }

    // MARK: - Missing key (returns key as placeholder)

    private var missingKeySection: some View {
        scenarioCard(title: "Missing key", note: "Key not in API or bundle → returns key") {
            row("nonexistent_key_xyz", LocalizeSDK.getString("nonexistent_key_xyz"))
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            HStack(spacing: 8) {
                Button("Refresh from API") { LocalizeSDK.refresh(); refreshId = UUID() }
                    .buttonStyle(.borderedProminent)
                Button("English") { LocalizeSDK.setLocale("en"); refreshId = UUID() }
                    .buttonStyle(.bordered)
                Button("Arabic") { LocalizeSDK.setLocale("ar"); refreshId = UUID() }
                    .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Helpers

    private func scenarioCard<Content: View>(title: String, note: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(note).font(.caption).foregroundStyle(.secondary)
            content()
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption)
                .lineLimit(2)
        }
    }
}

extension Notification.Name {
    static let localizeKeysUpdated = Notification.Name("LocalizeSDKKeysUpdated")
}

#Preview {
    ContentView()
}
