import Foundation
import SwiftUI
import Charts

struct RatingDataPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let rating: Int

    static func == (lhs: RatingDataPoint, rhs: RatingDataPoint) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.rating == rhs.rating
    }
}

struct RatingTrendChartView: View {
    let logs: [ConditionLog]
    let selectedLogId: UUID?

    @State private var dataPoints: [RatingDataPoint] = []
    @State private var animatedDataPoints: [RatingDataPoint] = []
    @State private var isAnimating: Bool = false

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)
    private let highlightColor = Color.yellow

    private func computeDataPoints(from logs: [ConditionLog]) -> [RatingDataPoint] {
        logs
            .compactMap { log -> RatingDataPoint? in
                guard let rating = log.overallRating,
                      let date = log.parsedDate else { return nil }
                return RatingDataPoint(id: log.id, date: date, rating: rating)
            }
            .sorted { $0.date < $1.date }
    }

    private func updateDataPoints(newPoints: [RatingDataPoint]) {
        // Animate the transition
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            dataPoints = newPoints
        }
    }

    var body: some View {
        Group {
            if dataPoints.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onAppear {
            // Initial load with animation
            let newPoints = computeDataPoints(from: logs)
            withAnimation(.easeOut(duration: 0.8)) {
                dataPoints = newPoints
            }
        }
        .onChange(of: logs.map { "\($0.id)-\($0.overallRating ?? 0)" }) { _, _ in
            // Data changed - animate the update
            let newPoints = computeDataPoints(from: logs)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                dataPoints = newPoints
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Add ratings to see trend")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var chartView: some View {
        Chart(dataPoints) { point in
            // Area fill under the line for visual effect
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [accentCyan.opacity(0.3), accentCyan.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", point.date),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(accentCyan)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            // Regular points
            PointMark(
                x: .value("Date", point.date),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(point.id == selectedLogId ? highlightColor : accentCyan)
            .symbolSize(point.id == selectedLogId ? 150 : 60)

            // Add glow for selected point
            if point.id == selectedLogId {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Rating", point.rating)
                )
                .foregroundStyle(highlightColor.opacity(0.3))
                .symbolSize(350)
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding()
        .contentTransition(.numericText())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: dataPoints)
        .animation(.easeInOut(duration: 0.3), value: selectedLogId)
    }
}
