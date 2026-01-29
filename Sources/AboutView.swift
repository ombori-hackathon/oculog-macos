import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App icon
            appIcon
                .frame(width: 128, height: 128)

            // App name
            Text(AppVersion.appName)
                .font(.system(size: 24, weight: .semibold))

            // Version
            Text("v\(AppVersion.version)")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 300, height: 280)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let icon = loadAppIcon() {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "eye.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.5, green: 0.2, blue: 0.9),
                            Color(red: 0.0, green: 0.8, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func loadAppIcon() -> NSImage? {
        let bundle = Bundle.module
        guard let resourceURL = bundle.resourceURL else { return nil }

        let iconURL = resourceURL
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
            .appendingPathComponent("icon_512x512@2x.png")

        return NSImage(contentsOf: iconURL)
    }
}
