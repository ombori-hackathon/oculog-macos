import SwiftUI

struct SplashView: View {
    @ObservedObject var appState: AppState
    @State private var dotCount: Int = 0
    @State private var timer: Timer?

    private let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)

    var body: some View {
        ZStack {
            // Dark background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Eye animation
                EyeAnimationView()

                // Status area
                VStack(spacing: 16) {
                    switch appState.loadingState {
                    case .loading:
                        loadingView

                    case .loaded:
                        loadedView

                    case .error(let message):
                        errorView(message: message)
                    }
                }
                .frame(height: 100)

                // Branding
                VStack(spacing: 8) {
                    Text("OCULOG")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .tracking(12)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.2, blue: 0.9),
                                    Color(red: 0.0, green: 0.8, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("v\(AppVersion.version)")
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .task {
            await appState.loadData()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            // Animated dots
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index <= dotCount ? Color(red: 0.0, green: 0.8, blue: 0.8) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .onAppear {
                startDotAnimation()
            }

            Text("Initializing...")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .onChange(of: appState.loadingState) { _, newValue in
            if case .loading = newValue {
                // Keep animating
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private var loadedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(Color(red: 0.0, green: 0.8, blue: 0.8))

            Text("Ready")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await appState.retry()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 0.5, green: 0.2, blue: 0.9))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func startDotAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            DispatchQueue.main.async {
                dotCount = (dotCount + 1) % 6
            }
        }
    }
}
