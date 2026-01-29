import SwiftUI
import AppKit

@main
struct OculogApp: App {
    @StateObject private var authState: AuthState
    @StateObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

    private static var defaultWindowSize: CGSize {
        if let screen = NSScreen.main {
            return CGSize(
                width: max(800, screen.frame.width * 0.7),
                height: max(600, screen.frame.height * 0.7)
            )
        }
        return CGSize(width: 1000, height: 700)
    }

    init() {
        // Initialize with shared authState
        let auth = AuthState()
        _authState = StateObject(wrappedValue: auth)
        _appState = StateObject(wrappedValue: AppState(authState: auth))

        // Required for swift run to show GUI window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Set dock icon from bundled resources
        setAppIcon()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isLoading {
                    // Auth loading state
                    ZStack {
                        Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()
                        ProgressView()
                            .controlSize(.large)
                    }
                } else if !authState.isAuthenticated {
                    // Not authenticated - show login
                    LoginView(authState: authState)
                } else {
                    // Authenticated - show main app
                    switch appState.loadingState {
                    case .loading, .error:
                        SplashView(appState: appState)
                    case .loaded:
                        ContentView(appState: appState)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appState.loadingState)
            .animation(.easeInOut(duration: 0.3), value: authState.isAuthenticated)
            .onReceive(appState.locationManager.$location) { newLocation in
                if newLocation != nil {
                    appState.refreshWeather()
                }
            }
            .task {
                await authState.checkAuth()
            }
            .onChange(of: authState.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    Task {
                        await appState.loadData()
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: Self.defaultWindowSize.width, height: Self.defaultWindowSize.height)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About \(AppVersion.appName)") {
                    openWindow(id: "about")
                }
            }
        }

        Window("About \(AppVersion.appName)", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
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
