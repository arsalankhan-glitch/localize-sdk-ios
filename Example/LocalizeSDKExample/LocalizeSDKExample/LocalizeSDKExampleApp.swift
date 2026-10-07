import SwiftUI
import LocalizeSDK

@main
struct LocalizeSDKExampleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var ready = false

    var body: some View {
        Group {
            if ready {
                ContentView()
            } else {
                ProgressView("Configuring SDK…")
            }
        }
        .task {
            await LocalizeSDK.configure(
                apiKey: ProcessInfo.processInfo.environment["LOCALIZE_EXAMPLE_API_KEY"] ?? "",
                onKeysUpdated: { NotificationCenter.default.post(name: .localizeKeysUpdated, object: nil) },
                fallbackLocale: "en",
                enableLogging: false
            )
            ready = true
        }
    }
}
