import SwiftUI
import AppKit

// MARK: - Sortable Column Header

struct SortableColumnHeader: View {
    let title: String
    let field: SortField
    let currentSortField: SortField
    let sortOrder: SortOrder
    let alignment: Alignment
    let onSort: (SortField) -> Void

    private var isActive: Bool {
        currentSortField == field
    }

    var body: some View {
        Button {
            onSort(field)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .fontWeight(isActive ? .semibold : .regular)
                if isActive {
                    Image(systemName: sortOrder.arrowSymbol)
                        .font(.caption)
                }
            }
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(maxWidth: .infinity, alignment: alignment)
        }
        .buttonStyle(.plain)
        .help("Sort by \(title.lowercased())")
    }
}

// MARK: - Logs Table

struct LogsTable: View {
    let logs: [ConditionLog]
    let sortField: SortField
    let sortOrder: SortOrder
    let onRowDoubleClick: (ConditionLog) -> Void
    let onDelete: (ConditionLog) -> Void
    let onSort: (SortField) -> Void

    @Binding var selection: ConditionLog.ID?
    @State private var logToDelete: ConditionLog?
    @State private var showDeleteConfirmation: Bool = false
    @State private var lastClickTime: Date = .distantPast
    @State private var lastClickedId: ConditionLog.ID?

    private let deleteWidth: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - deleteWidth - 40 // 40 for padding
            let dateWidth = availableWidth * 0.20
            let ratingWidth = availableWidth * 0.20
            let cityWidth = availableWidth * 0.30
            let commentsWidth = availableWidth * 0.30

            VStack(spacing: 0) {
                // Custom sortable header row
                HStack(spacing: 0) {
                    SortableColumnHeader(
                        title: "Date",
                        field: .date,
                        currentSortField: sortField,
                        sortOrder: sortOrder,
                        alignment: .leading,
                        onSort: onSort
                    )
                    .frame(width: dateWidth)

                    SortableColumnHeader(
                        title: "Rating",
                        field: .rating,
                        currentSortField: sortField,
                        sortOrder: sortOrder,
                        alignment: .center,
                        onSort: onSort
                    )
                    .frame(width: ratingWidth)

                    SortableColumnHeader(
                        title: "City",
                        field: .city,
                        currentSortField: sortField,
                        sortOrder: sortOrder,
                        alignment: .leading,
                        onSort: onSort
                    )
                    .frame(width: cityWidth)

                    Text("Comments")
                        .foregroundStyle(.secondary)
                        .frame(width: commentsWidth, alignment: .leading)

                    Spacer()
                        .frame(width: deleteWidth)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Custom List-based table for better alignment control
                List(logs, selection: $selection) { log in
                    HStack(spacing: 0) {
                        Text(log.formattedDate)
                            .frame(width: dateWidth, alignment: .leading)

                        Text(log.ratingDisplay)
                            .monospacedDigit()
                            .frame(width: ratingWidth, alignment: .center)

                        Text(log.city ?? "–")
                            .foregroundStyle(log.city == nil ? .secondary : .primary)
                            .frame(width: cityWidth, alignment: .leading)

                        Text(log.truncatedComments)
                            .foregroundStyle(log.comments == nil ? .secondary : .primary)
                            .frame(width: commentsWidth, alignment: .leading)
                            .lineLimit(1)

                        Button {
                            logToDelete = log
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .frame(width: deleteWidth)
                        .help("Delete log")
                    }
                    .contentShape(Rectangle())
                    .tag(log.id)
                }
                .listStyle(.plain)
                .onChange(of: selection) { oldValue, newValue in
                    let now = Date()
                    if let newId = newValue,
                       newId == lastClickedId,
                       now.timeIntervalSince(lastClickTime) < 0.4 {
                        if let log = logs.first(where: { $0.id == newId }) {
                            onRowDoubleClick(log)
                        }
                    }
                    lastClickTime = now
                    lastClickedId = newValue
                }
                .contextMenu(forSelectionType: ConditionLog.ID.self) { selectedIds in
                    if let id = selectedIds.first,
                       let log = logs.first(where: { $0.id == id }) {
                        Button("Edit") {
                            onRowDoubleClick(log)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            logToDelete = log
                            showDeleteConfirmation = true
                        }
                    }
                } primaryAction: { selectedIds in
                    if let id = selectedIds.first,
                       let log = logs.first(where: { $0.id == id }) {
                        onRowDoubleClick(log)
                    }
                }
            }
        }
        .alert("Delete Log?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                logToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    onDelete(log)
                }
                logToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
