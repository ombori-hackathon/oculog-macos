import SwiftUI

struct RatingSliderView: View {
    let label: String
    let icon: String
    @Binding var value: Int?
    var isRequired: Bool = false
    var highIsGood: Bool = false  // If true, 10=green, 0=red (for quality ratings)

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

                if value != nil {
                    Button {
                        value = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Clear")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 4) {
                ForEach(0...10, id: \.self) { index in
                    RatingSegment(
                        index: index,
                        isSelected: value == index,
                        color: colorForRating(index)
                    ) {
                        value = index
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForRating(_ rating: Int) -> Color {
        let ratio = Double(rating) / 10.0
        let effectiveRatio = highIsGood ? (1.0 - ratio) : ratio  // Invert for quality ratings

        if effectiveRatio < 0.3 {
            return Color(red: 0.2, green: 0.8, blue: 0.4)  // Green
        } else if effectiveRatio < 0.6 {
            return Color(red: 0.9, green: 0.8, blue: 0.2)  // Yellow
        } else {
            return Color(red: 0.9, green: 0.3, blue: 0.3)  // Red
        }
    }
}

struct RatingSegment: View {
    let index: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? color : color.opacity(0.3))
                    .frame(height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )

                Text("\(index)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

