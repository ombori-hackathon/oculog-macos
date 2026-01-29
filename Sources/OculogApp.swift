import SwiftUI
import AppKit

@main
struct OculogApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Required for swift run to show GUI window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Set dock icon from bundled resources
        setAppIcon()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.loadingState {
                case .loading, .error:
                    SplashView(appState: appState)
                case .loaded:
                    ContentView(items: appState.items, apiStatus: appState.apiStatus)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appState.loadingState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
    }

    private func setAppIcon() {
        let bundle = Bundle.module

        // Build path to icon in the copied Assets.xcassets
        guard let resourceURL = bundle.resourceURL else { return }
        let iconURL = resourceURL
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
            .appendingPathComponent("icon_512x512@2x.png")

        if let image = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = image
        }
    }
}
