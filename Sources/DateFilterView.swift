import SwiftUI

struct DateFilterView: View {
    @ObservedObject var appState: AppState
    @State private var showingPopover = false
    @State private var rangeError: String?

    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                Text(appState.dateFilterPreset.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .popover(isPresented: $showingPopover) {
            filterPopoverContent
                .frame(width: 300)
        }
    }

    private var filterPopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)

            ForEach(DateFilterPreset.allCases, id: \.self) { preset in
                if preset != .custom {
                    Button {
                        appState.dateFilterPreset = preset
                        showingPopover = false
                        Task { await appState.refreshLogs() }
                    } label: {
                        HStack {
                            Text(preset.rawValue)
                            Spacer()
                            if appState.dateFilterPreset == preset {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accentCyan)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Text("Custom Range")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            DatePicker("From", selection: $appState.customStartDate, displayedComponents: .date)
            DatePicker("To", selection: $appState.customEndDate, displayedComponents: .date)

            if let error = rangeError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Apply Custom Range") {
                // Validate max 3 months
                let months = Calendar.current.dateComponents(
                    [.month],
                    from: appState.customStartDate,
                    to: appState.customEndDate
                ).month ?? 0

                if months > 3 {
                    rangeError = "Date range cannot exceed 3 months"
                    return
                }

                if appState.customStartDate > appState.customEndDate {
                    rangeError = "Start date must be before end date"
                    return
                }

                rangeError = nil
                appState.dateFilterPreset = .custom
                showingPopover = false
                Task { await appState.refreshLogs() }
            }
            .buttonStyle(.borderedProminent)
            .tint(accentCyan)
        }
        .padding()
    }
}
