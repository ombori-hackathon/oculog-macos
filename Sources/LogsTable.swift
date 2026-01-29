import SwiftUI

struct LogsTable: View {
    let logs: [ConditionLog]
    let onRowDoubleClick: (ConditionLog) -> Void
    let onDelete: (ConditionLog) -> Void

    @Binding var selection: ConditionLog.ID?
    @State private var logToDelete: ConditionLog?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        Table(logs, selection: $selection) {
            TableColumn("Date") { log in
                Text(log.formattedDate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        onRowDoubleClick(log)
                    }
                    .onTapGesture(count: 1) {
                        selection = log.id
                    }
            }
            .width(min: 100, ideal: 120)

            TableColumn("Rating") { log in
                Text(log.ratingDisplay)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        onRowDoubleClick(log)
                    }
                    .onTapGesture(count: 1) {
                        selection = log.id
                    }
            }
            .width(60)

            TableColumn("Comments") { log in
                Text(log.truncatedComments)
                    .foregroundStyle(log.comments == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        onRowDoubleClick(log)
                    }
                    .onTapGesture(count: 1) {
                        selection = log.id
                    }
            }

            TableColumn("") { log in
                Button {
                    logToDelete = log
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Delete log")
            }
            .width(30)
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

