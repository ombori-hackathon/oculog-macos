import SwiftUI

struct ConditionLogFormView: View {
    let editingLog: ConditionLog?
    let detectedCity: String?  // Passed from AppState.weatherState
    let onSave: (ConditionLogCreate) async throws -> Void
    let onUpdate: (UUID, ConditionLogUpdate) async throws -> Void
    let onCancel: () -> Void
    var onOpenExisting: ((UUID) -> Void)? = nil

    @State private var logDate: Date = Date()
    @State private var city: String = ""

    // Symptoms
    @State private var burning: Int?
    @State private var redness: Int?
    @State private var itching: Int?
    @State private var tearing: Int?
    @State private var swelling: Int?
    @State private var dryness: Int?
    @State private var overallRating: Int?

    // Lifestyle
    @State private var screenTimeHours: Double?
    @State private var sleepHours: Double?
    @State private var sleepQuality: Int?
    @State private var waterIntakeLiters: Double?
    @State private var caffeineCups: Int?
    @State private var alcoholUnits: Int?
    @State private var stressLevel: Int?
    @State private var outdoorHours: Double?

    // Treatments
    @State private var usedArtificialTears: Bool = false
    @State private var usedWarmCompress: Bool = false
    @State private var usedLidScrub: Bool = false
    @State private var usedPrescriptionDrops: Bool = false
    @State private var usedOmega3: Bool = false
    @State private var usedHumidifier: Bool = false

    // Environment
    @State private var woreContacts: Bool = false
    @State private var acExposure: Bool = false
    @State private var heatingExposure: Bool = false

    // Notes
    @State private var treatmentsNotes: String = ""
    @State private var comments: String = ""

    // UI State
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showDuplicateDateAlert: Bool = false
    @State private var existingLogId: UUID?
    @State private var showExtraLifestyle: Bool = false

    private var isEditMode: Bool { editingLog != nil }

    // MARK: - Validation

    private let maxTextLength = 500
    private let maxCityLength = 50

    private var validationError: String? {
        // City validation
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            return "City is required"
        }
        if city.count > maxCityLength {
            return "City must be \(maxCityLength) characters or less"
        }

        // Required symptoms
        let symptoms: [(String, Int?)] = [
            ("Overall Rating", overallRating), ("Burning", burning),
            ("Redness", redness), ("Itching", itching),
            ("Tearing", tearing), ("Swelling", swelling), ("Dryness", dryness)
        ]
        for (name, value) in symptoms where value == nil {
            return "\(name) is required"
        }

        // Required lifestyle
        let lifestyle: [(String, Bool)] = [
            ("Screen Time", screenTimeHours != nil),
            ("Sleep Hours", sleepHours != nil),
            ("Sleep Quality", sleepQuality != nil),
            ("Stress Level", stressLevel != nil),
            ("Outdoor Hours", outdoorHours != nil)
        ]
        for (name, hasValue) in lifestyle where !hasValue {
            return "\(name) is required"
        }

        // Max hours validation
        if let h = sleepHours, h > 24 { return "Sleep hours cannot exceed 24" }
        if let h = screenTimeHours, h > 24 { return "Screen time cannot exceed 24" }
        if let h = outdoorHours, h > 24 { return "Outdoor hours cannot exceed 24" }

        // Text length validation
        if comments.count > maxTextLength { return "Comments must be \(maxTextLength) characters or less" }
        if treatmentsNotes.count > maxTextLength { return "Treatment notes must be \(maxTextLength) characters or less" }

        return nil
    }

    private var isFormValid: Bool { validationError == nil }

    private let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    private let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.8)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Form content
            ScrollView {
                VStack(spacing: 16) {
                    // Weather section (only when editing and weather exists)
                    if let log = editingLog, let weather = log.weather {
                        WeatherDisplayView(weather: weather, compact: false)
                    }

                    dateAndLocationSection
                    symptomsSection
                    lifestyleSection
                    treatmentsSection
                    environmentSection
                    notesSection
                }
                .padding()
            }

            // Error banner
            if let error = errorMessage {
                ErrorBanner(
                    message: error,
                    style: .error,
                    onDismiss: { errorMessage = nil }
                )
                .padding(.horizontal)
            }

            Divider()

            // Footer with buttons
            footer
        }
        .frame(width: 620, height: 850)
        .background(backgroundColor)
        .onAppear(perform: populateFromEditingLog)
        .alert("Log Already Exists", isPresented: $showDuplicateDateAlert) {
            Button("Open Existing") {
                if let id = existingLogId {
                    onCancel()
                    onOpenExisting?(id)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("A log for this date already exists. Would you like to open it?")
        }
    }

    private var header: some View {
        HStack {
            Text(isEditMode ? "Edit Log" : "New Log")
                .font(.title2.bold())

            Spacer()

            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.bar)
    }

    private var dateAndLocationSection: some View {
        FormSection(title: "Date & Location", icon: "calendar") {
            VStack(spacing: 16) {
                // Large graphical date picker for accessibility
                DatePicker(
                    "Log Date",
                    selection: $logDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .controlSize(.large)
                .transformEffect(.init(scaleX: 1.3, y: 1.3))
                .frame(minHeight: 350)

                Divider()

                // City text field with required indicator
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.cyan)
                        Text("Location")
                            .font(.system(size: 14))
                        Text("*")
                            .foregroundStyle(.red)
                            .font(.system(size: 14))
                    }
                    Spacer()
                    TextField("City, Country", text: $city)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .frame(maxWidth: 200)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("\(city.count)/\(maxCityLength)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(city.count > maxCityLength ? .red : .secondary)
                }
            }
        }
    }

    private var symptomsSection: some View {
        FormSection(title: "Symptoms", icon: "eye") {
            VStack(spacing: 8) {
                RatingSliderView(label: "Overall Rating", icon: "star.fill", value: $overallRating, isRequired: true)
                RatingSliderView(label: "Burning", icon: "flame", value: $burning, isRequired: true)
                RatingSliderView(label: "Redness", icon: "eye", value: $redness, isRequired: true)
                RatingSliderView(label: "Itching", icon: "hand.raised", value: $itching, isRequired: true)
                RatingSliderView(label: "Tearing", icon: "drop", value: $tearing, isRequired: true)
                RatingSliderView(label: "Swelling", icon: "circle.circle", value: $swelling, isRequired: true)
                RatingSliderView(label: "Dryness", icon: "drop.triangle", value: $dryness, isRequired: true)
            }
        }
    }

    private var lifestyleSection: some View {
        FormSection(title: "Lifestyle", icon: "figure.walk") {
            VStack(spacing: 4) {
                // Required fields
                HoursInputView(label: "Screen Time", icon: "tv", value: $screenTimeHours, maxValue: 24, isRequired: true)
                HoursInputView(label: "Sleep Hours", icon: "bed.double", value: $sleepHours, maxValue: 24, isRequired: true)
                RatingSliderView(label: "Sleep Quality", icon: "moon.zzz", value: $sleepQuality, isRequired: true)
                RatingSliderView(label: "Stress Level", icon: "brain.head.profile", value: $stressLevel, isRequired: true)
                HoursInputView(label: "Outdoor Hours", icon: "sun.max", value: $outdoorHours, maxValue: 24, isRequired: true)

                // Custom collapsible header (entire row clickable)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showExtraLifestyle.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showExtraLifestyle ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.cyan)
                        Text("Extra (Optional)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())  // Makes entire row tappable
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if showExtraLifestyle {
                    VStack(spacing: 4) {
                        HoursInputView(label: "Water Intake (L)", icon: "drop.fill", value: $waterIntakeLiters, maxValue: 10, step: 0.25)
                        IntegerInputView(label: "Caffeine Cups", icon: "cup.and.saucer", value: $caffeineCups, maxValue: 20)
                        IntegerInputView(label: "Alcohol Units", icon: "wineglass", value: $alcoholUnits, maxValue: 20)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var treatmentsSection: some View {
        FormSection(title: "Treatments", icon: "cross.case") {
            FlowLayout(spacing: 8) {
                ToggleChip(label: "Artificial Tears", icon: "drop", isOn: $usedArtificialTears)
                ToggleChip(label: "Warm Compress", icon: "flame", isOn: $usedWarmCompress)
                ToggleChip(label: "Lid Scrub", icon: "hands.sparkles", isOn: $usedLidScrub)
                ToggleChip(label: "Prescription Drops", icon: "cross.vial", isOn: $usedPrescriptionDrops)
                ToggleChip(label: "Omega-3", icon: "fish", isOn: $usedOmega3)
                ToggleChip(label: "Humidifier", icon: "humidity", isOn: $usedHumidifier)
            }
        }
    }

    private var environmentSection: some View {
        FormSection(title: "Environment", icon: "leaf") {
            FlowLayout(spacing: 8) {
                ToggleChip(label: "Wore Contacts", icon: "eye.circle", isOn: $woreContacts)
                ToggleChip(label: "AC Exposure", icon: "air.conditioner.horizontal", isOn: $acExposure)
                ToggleChip(label: "Heating", icon: "heater.vertical", isOn: $heatingExposure)
            }
        }
    }

    private var notesSection: some View {
        FormSection(title: "Notes", icon: "note.text") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Treatment Notes")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(treatmentsNotes.count)/\(maxTextLength)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(treatmentsNotes.count > maxTextLength ? .red : .secondary)
                    }
                    TextEditor(text: $treatmentsNotes)
                        .font(.system(size: 13))
                        .frame(height: 60)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(treatmentsNotes.count > maxTextLength ? Color.red : Color.clear, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("General Comments")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(comments.count)/\(maxTextLength)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(comments.count > maxTextLength ? .red : .secondary)
                    }
                    TextEditor(text: $comments)
                        .font(.system(size: 13))
                        .frame(height: 60)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(comments.count > maxTextLength ? Color.red : Color.clear, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Button {
                Task {
                    await saveLog()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 60)
                } else {
                    Text("Save")
                        .frame(width: 60)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(accentCyan)
            .disabled(isSaving || !isFormValid)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
        .background(.bar)
    }

    private func populateFromEditingLog() {
        guard let log = editingLog else {
            // Pre-populate city from detected location (only for new logs)
            if let detected = detectedCity {
                city = String(detected.prefix(maxCityLength))
            }
            return
        }

        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: log.logDate) {
            logDate = date
        }

        // City
        city = log.city ?? ""

        // Symptoms
        burning = log.burning
        redness = log.redness
        itching = log.itching
        tearing = log.tearing
        swelling = log.swelling
        dryness = log.dryness
        overallRating = log.overallRating

        // Lifestyle
        screenTimeHours = log.screenTimeHours
        sleepHours = log.sleepHours
        sleepQuality = log.sleepQuality
        waterIntakeLiters = log.waterIntakeLiters
        caffeineCups = log.caffeineCups
        alcoholUnits = log.alcoholUnits
        stressLevel = log.stressLevel
        outdoorHours = log.outdoorHours

        // Treatments
        usedArtificialTears = log.usedArtificialTears ?? false
        usedWarmCompress = log.usedWarmCompress ?? false
        usedLidScrub = log.usedLidScrub ?? false
        usedPrescriptionDrops = log.usedPrescriptionDrops ?? false
        usedOmega3 = log.usedOmega3 ?? false
        usedHumidifier = log.usedHumidifier ?? false

        // Environment
        woreContacts = log.woreContacts ?? false
        acExposure = log.acExposure ?? false
        heatingExposure = log.heatingExposure ?? false

        // Notes
        treatmentsNotes = log.treatmentsNotes ?? ""
        comments = log.comments ?? ""
    }

    private func saveLog() async {
        errorMessage = nil

        if let error = validationError {
            errorMessage = error
            return
        }

        isSaving = true
        defer { isSaving = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: logDate)

        do {
            if let existingLog = editingLog {
                var update = ConditionLogUpdate()
                update.logDate = dateString
                update.city = city
                update.overallRating = overallRating
                update.comments = comments.isEmpty ? nil : comments
                update.burning = burning
                update.redness = redness
                update.itching = itching
                update.tearing = tearing
                update.swelling = swelling
                update.dryness = dryness
                update.screenTimeHours = screenTimeHours
                update.sleepHours = sleepHours
                update.sleepQuality = sleepQuality
                update.waterIntakeLiters = waterIntakeLiters
                update.caffeineCups = caffeineCups
                update.alcoholUnits = alcoholUnits
                update.stressLevel = stressLevel
                update.outdoorHours = outdoorHours
                update.usedArtificialTears = usedArtificialTears
                update.usedWarmCompress = usedWarmCompress
                update.usedLidScrub = usedLidScrub
                update.usedPrescriptionDrops = usedPrescriptionDrops
                update.usedOmega3 = usedOmega3
                update.usedHumidifier = usedHumidifier
                update.woreContacts = woreContacts
                update.acExposure = acExposure
                update.heatingExposure = heatingExposure
                update.treatmentsNotes = treatmentsNotes.isEmpty ? nil : treatmentsNotes

                try await onUpdate(existingLog.id, update)
            } else {
                var create = ConditionLogCreate(logDate: dateString, city: city)
                create.overallRating = overallRating
                create.comments = comments.isEmpty ? nil : comments
                create.burning = burning
                create.redness = redness
                create.itching = itching
                create.tearing = tearing
                create.swelling = swelling
                create.dryness = dryness
                create.screenTimeHours = screenTimeHours
                create.sleepHours = sleepHours
                create.sleepQuality = sleepQuality
                create.waterIntakeLiters = waterIntakeLiters
                create.caffeineCups = caffeineCups
                create.alcoholUnits = alcoholUnits
                create.stressLevel = stressLevel
                create.outdoorHours = outdoorHours
                create.usedArtificialTears = usedArtificialTears
                create.usedWarmCompress = usedWarmCompress
                create.usedLidScrub = usedLidScrub
                create.usedPrescriptionDrops = usedPrescriptionDrops
                create.usedOmega3 = usedOmega3
                create.usedHumidifier = usedHumidifier
                create.woreContacts = woreContacts
                create.acExposure = acExposure
                create.heatingExposure = heatingExposure
                create.treatmentsNotes = treatmentsNotes.isEmpty ? nil : treatmentsNotes

                try await onSave(create)
            }
        } catch let error as APIError {
            if error.errorType == .duplicateDate {
                existingLogId = error.existingLogId
                showDuplicateDateAlert = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0

        return (CGSize(width: max(totalWidth, maxWidth), height: totalHeight), positions)
    }
}
