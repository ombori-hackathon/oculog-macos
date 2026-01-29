import SwiftUI

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    private let sectionBackground = Color(red: 0.15, green: 0.15, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ToggleChip: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? accentCyan.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundStyle(isOn ? accentCyan : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isOn ? accentCyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HoursInputView: View {
    let label: String
    let icon: String
    @Binding var value: Double?
    let maxValue: Double
    let step: Double
    var isRequired: Bool = false

    init(label: String, icon: String, value: Binding<Double?>, maxValue: Double = 24, step: Double = 0.5, isRequired: Bool = false) {
        self.label = label
        self.icon = icon
        self._value = value
        self.maxValue = maxValue
        self.step = step
        self.isRequired = isRequired
    }

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(accentCyan)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 13))
                if isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                        .font(.system(size: 13))
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    let current = value ?? 0
                    if current > 0 {
                        value = max(0, current - step)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.secondary.opacity(value == nil || value == 0 ? 0.4 : 1.0))
                }
                .buttonStyle(.plain)
                .disabled(value == nil || value == 0)

                Text(value.map { String(format: "%.1f", $0) } ?? "–")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .frame(width: 50)

                Button {
                    let current = value ?? 0
                    if current < maxValue {
                        value = min(maxValue, current + step)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(accentCyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

struct IntegerInputView: View {
    let label: String
    let icon: String
    @Binding var value: Int?
    let maxValue: Int

    init(label: String, icon: String, value: Binding<Int?>, maxValue: Int = 20) {
        self.label = label
        self.icon = icon
        self._value = value
        self.maxValue = maxValue
    }

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(accentCyan)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 13))
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    let current = value ?? 0
                    if current > 0 {
                        value = current - 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.secondary.opacity(value == nil || value == 0 ? 0.4 : 1.0))
                }
                .buttonStyle(.plain)
                .disabled(value == nil || value == 0)

                Text(value.map { "\($0)" } ?? "–")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .frame(width: 40)

                Button {
                    let current = value ?? 0
                    if current < maxValue {
                        value = current + 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(accentCyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ErrorBanner: View {
    let message: String
    let style: ErrorBannerStyle
    var onDismiss: (() -> Void)?
    var onRetry: (() -> Void)?

    enum ErrorBannerStyle {
        case warning
        case error

        var color: Color {
            switch self {
            case .warning: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Spacer()

            if let onRetry = onRetry {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(style.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
