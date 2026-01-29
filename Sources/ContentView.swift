import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    @State private var tableSelection: ConditionLog.ID?
    @State private var chartHeight: CGFloat = 0

    private let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)
    private let minChartHeight: CGFloat = 150
    private let minListHeight: CGFloat = 200

    private var detectedCity: String? {
        if case .loaded(let weather) = appState.weatherState.state {
            return weather.locationName
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Oculog v\(AppVersion.version)")
                        .font(.title.bold())

                    Button {
                        appState.openLogForm()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(accentCyan)
                    }
                    .buttonStyle(.plain)
                    .help("Add new log entry")

                    DateFilterView(appState: appState)

                    Spacer()

                    WeatherHeaderView(
                        locationManager: appState.locationManager,
                        weatherState: appState.weatherState,
                        onRetry: { appState.locationManager.requestLocation() }
                    )

                    Spacer()

                    Circle()
                        .fill(appState.apiStatus == "healthy" ? .green : .red)
                        .frame(width: 12, height: 12)
                    Text(appState.apiStatus)
                        .foregroundStyle(.secondary)

                    Button {
                        appState.authState.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Log out")
                }
                .padding()
                .background(.bar)

                Divider()

                // Error banner for fetch failures
                if let error = appState.listError {
                    ErrorBanner(
                        message: error,
                        style: .warning,
                        onRetry: {
                            Task {
                                await appState.refreshLogs()
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Content
                VStack(spacing: 0) {
                    if appState.logs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "eye")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No logs yet")
                                .foregroundStyle(.secondary)
                            Text("Click + to add your first entry")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(backgroundColor)
                    } else {
                        // Chart section
                        RatingTrendChartView(logs: appState.logs)
                            .frame(height: chartHeight)

                        // Resizable divider
                        ResizableDivider(
                            chartHeight: $chartHeight,
                            minChartHeight: minChartHeight,
                            maxChartHeight: geometry.size.height - minListHeight - 100 // Account for header
                        )

                        // Logs table and pagination
                        VStack(spacing: 0) {
                            LogsTable(
                                logs: appState.logs,
                                onRowDoubleClick: { log in
                                    appState.openLogForm(editing: log)
                                },
                                onDelete: { log in
                                    Task {
                                        try? await appState.deleteLog(id: log.id)
                                    }
                                },
                                selection: $tableSelection
                            )
                            .background(backgroundColor)

                            PaginationView(appState: appState)
                        }
                    }
                }
            }
            .background(backgroundColor)
            .onAppear {
                // Initialize chart height to 1/3 of content area
                if chartHeight == 0 {
                    chartHeight = max(minChartHeight, (geometry.size.height - 100) / 3)
                }
            }
        }
        .sheet(isPresented: $appState.isShowingLogForm) {
            ConditionLogFormView(
                editingLog: appState.editingLog,
                detectedCity: detectedCity,
                onSave: { log in
                    _ = try await appState.createLog(log)
                    appState.closeLogForm()
                },
                onUpdate: { id, update in
                    _ = try await appState.updateLog(id: id, update)
                    appState.closeLogForm()
                },
                onCancel: {
                    appState.closeLogForm()
                },
                onOpenExisting: { logId in
                    // Find the existing log and open it for editing
                    if let existingLog = appState.logs.first(where: { $0.id == logId }) {
                        appState.openLogForm(editing: existingLog)
                    }
                }
            )
        }
    }
}

// MARK: - Resizable Divider

struct ResizableDivider: View {
    @Binding var chartHeight: CGFloat
    let minChartHeight: CGFloat
    let maxChartHeight: CGFloat

    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 8)
            .overlay {
                Capsule()
                    .fill(isHovering ? Color.gray : Color.gray.opacity(0.5))
                    .frame(width: 40, height: 4)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = chartHeight + value.translation.height
                        chartHeight = min(max(newHeight, minChartHeight), maxChartHeight)
                    }
            )
    }
}
