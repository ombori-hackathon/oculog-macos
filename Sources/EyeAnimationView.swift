import SwiftUI

struct EyeAnimationView: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pupilScale: Double = 1.0
    @State private var glowOpacity: Double = 0.5
    @State private var scanLineProgress: Double = 0
    @State private var shimmerOffset: Double = -1

    private let eyeSize: CGFloat = 200
    private let primaryColor = Color(red: 0.5, green: 0.2, blue: 0.9)   // Purple
    private let secondaryColor = Color(red: 0.0, green: 0.8, blue: 0.8) // Cyan

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: eyeSize * 0.4,
                        endRadius: eyeSize * 0.7
                    )
                )
                .frame(width: eyeSize * 1.4, height: eyeSize * 1.4)
                .opacity(glowOpacity)

            // Outer iris ring (rotates clockwise)
            IrisRing(segments: 24, innerRadius: eyeSize * 0.35, outerRadius: eyeSize * 0.48)
                .fill(
                    AngularGradient(
                        colors: [primaryColor, secondaryColor, primaryColor],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(outerRotation))

            // Middle iris ring (rotates counter-clockwise)
            IrisRing(segments: 16, innerRadius: eyeSize * 0.25, outerRadius: eyeSize * 0.34)
                .fill(
                    AngularGradient(
                        colors: [secondaryColor, primaryColor, secondaryColor],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(innerRotation))

            // Inner iris ring
            IrisRing(segments: 12, innerRadius: eyeSize * 0.15, outerRadius: eyeSize * 0.24)
                .fill(
                    AngularGradient(
                        colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8), primaryColor.opacity(0.8)],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(outerRotation * 0.5))

            // Pupil with gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black],
                        center: .center,
                        startRadius: 0,
                        endRadius: eyeSize * 0.15
                    )
                )
                .frame(width: eyeSize * 0.28, height: eyeSize * 0.28)
                .scaleEffect(pupilScale)

            // Pupil highlight
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: eyeSize * 0.06, height: eyeSize * 0.06)
                .offset(x: -eyeSize * 0.05, y: -eyeSize * 0.05)
                .scaleEffect(pupilScale)

            // Scanning lines overlay
            ScanLines(progress: scanLineProgress)
                .stroke(secondaryColor.opacity(0.3), lineWidth: 1)
                .frame(width: eyeSize, height: eyeSize)
                .clipShape(Circle())

            // Shimmer effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: shimmerOffset),
                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: shimmerOffset + 0.3)
                    )
                )
                .frame(width: eyeSize, height: eyeSize)
        }
        .frame(width: eyeSize * 1.4, height: eyeSize * 1.4)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Outer ring rotation (slow, mesmerizing)
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }

        // Inner ring rotation (opposite direction)
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }

        // Pupil pulsing (dilate/contract)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pupilScale = 1.15
        }

        // Glow pulsing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }

        // Scanning lines
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            scanLineProgress = 1
        }

        // Shimmer effect
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.5
        }
    }
}

// Custom shape for iris ring segments
struct IrisRing: Shape {
    let segments: Int
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let segmentAngle = 360.0 / Double(segments)
        let gapAngle = segmentAngle * 0.15

        for i in 0..<segments {
            let startAngle = Angle(degrees: Double(i) * segmentAngle + gapAngle / 2 - 90)
            let endAngle = Angle(degrees: Double(i + 1) * segmentAngle - gapAngle / 2 - 90)

            path.move(to: pointOnCircle(center: center, radius: innerRadius, angle: startAngle))
            path.addLine(to: pointOnCircle(center: center, radius: outerRadius, angle: startAngle))
            path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addLine(to: pointOnCircle(center: center, radius: innerRadius, angle: endAngle))
            path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        }

        return path
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(CGFloat(angle.radians)),
            y: center.y + radius * sin(CGFloat(angle.radians))
        )
    }
}

// Scanning lines that radiate outward
struct ScanLines: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2

        // Draw radiating lines
        for i in 0..<8 {
            let angle = Angle(degrees: Double(i) * 45 + progress * 360)
            let endPoint = CGPoint(
                x: center.x + maxRadius * cos(CGFloat(angle.radians)),
                y: center.y + maxRadius * sin(CGFloat(angle.radians))
            )
            path.move(to: center)
            path.addLine(to: endPoint)
        }

        // Draw expanding circle
        let circleRadius = maxRadius * progress.truncatingRemainder(dividingBy: 1.0)
        path.addEllipse(in: CGRect(
            x: center.x - circleRadius,
            y: center.y - circleRadius,
            width: circleRadius * 2,
            height: circleRadius * 2
        ))

        return path
    }
}

