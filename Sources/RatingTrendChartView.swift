import Foundation
import SwiftUI
import Charts

struct RatingDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let rating: Int
}

struct RatingTrendChartView: View {
    let logs: [ConditionLog]

    @State private var dataPoints: [RatingDataPoint] = []

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    private func computeDataPoints(from logs: [ConditionLog]) -> [RatingDataPoint] {
        logs
            .compactMap { log -> RatingDataPoint? in
                guard let rating = log.overallRating,
                      let date = log.parsedDate else { return nil }
                return RatingDataPoint(id: log.id, date: date, rating: rating)
            }
            .sorted { $0.date < $1.date }
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
            dataPoints = computeDataPoints(from: logs)
        }
        .onChange(of: logs.map(\.id)) { _, _ in
            dataPoints = computeDataPoints(from: logs)
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
            LineMark(
                x: .value("Date", point.date),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(accentCyan)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(accentCyan)
            .symbolSize(50)
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
    }
}
