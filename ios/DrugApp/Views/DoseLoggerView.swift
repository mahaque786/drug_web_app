import SwiftUI

/// Dose logger with interaction & timing warnings.
/// Equivalent to logger.html in the web app.
@MainActor
class DoseLoggerViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var logs: [MedicationLog] = []
    @Published var selectedMed: Medication?
    @Published var selectedDose: Double?
    @Published var reason = ""
    @Published var warnings: [Warning] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText = ""

    struct Warning: Identifiable {
        let id = UUID()
        let message: String
        let severity: String   // "info" | "warning" | "danger"
    }

    var filteredLogs: [MedicationLog] {
        guard !searchText.isEmpty else { return logs }
        let q = searchText.lowercased()
        return logs.filter {
            $0.medicationName.lowercased().contains(q) ||
            $0.dose.lowercased().contains(q) ||
            $0.reason.lowercased().contains(q)
        }
    }

    // MARK: - Load data

    func loadMedications() async {
        let svc = MedlistService()
        await svc.load()
        medications = svc.medications
    }

    func loadLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            logs = try await SupabaseService.shared.fetchMedicationLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Warnings

    func computeWarnings() {
        guard let med = selectedMed, let dose = selectedDose else {
            warnings = []
            return
        }
        var result: [Warning] = []
        let now = Date()

        // Time since last dose of same medication
        let sameMedLogs = logs.filter { $0.medicationName == med.genericName }
        if let lastLog = sameMedLogs.first,
           let lastTs = ISO8601DateFormatter().date(from: lastLog.timestamp ?? "") {
            let hoursSince = now.timeIntervalSince(lastTs) / 3600
            // Try to parse required hours from the field (rough parse)
            let reqHours = parseHours(from: med.timeRequiredBetweenDoses) ?? 4
            if hoursSince < reqHours {
                let h = String(format: "%.1f", hoursSince)
                result.append(Warning(
                    message: "Only \(h)h since last \(med.genericName) dose (minimum: \(reqHours)h).",
                    severity: "warning"
                ))
            }
        }

        // Interaction check with recent medications (past 24 h)
        let cutoff = now.addingTimeInterval(-86400)
        let recentNames = Set(
            logs
                .filter { ISO8601DateFormatter().date(from: $0.timestamp ?? "").map { $0 > cutoff } ?? false }
                .map { $0.medicationName }
        )
        for ix in med.interactions where recentNames.contains(ix.drug) {
            let sev = ix.severity.lowercased()
            let warnSev: String
            switch sev {
            case "lethal", "severe": warnSev = "danger"
            case "moderate":         warnSev = "warning"
            default:                 warnSev = "info"
            }
            result.append(Warning(
                message: "⚠️ Interaction with \(ix.drug) [\(ix.severity)]: \(ix.interaction)",
                severity: warnSev
            ))
        }

        // Daily dose limit check
        let todayStart = Calendar.current.startOfDay(for: now)
        let todayDoses = logs
            .filter {
                $0.medicationName == med.genericName &&
                (ISO8601DateFormatter().date(from: $0.timestamp ?? "").map { $0 >= todayStart } ?? false)
            }
            .compactMap { Double($0.dose.components(separatedBy: " ").first ?? "") }
        let totalToday = todayDoses.reduce(0, +) + dose
        if let maxStr = parseMaxDose(from: med.maximumDailyDosage), totalToday > maxStr {
            result.append(Warning(
                message: "Cumulative dose today (\(totalToday) \(med.doseUnit)) exceeds max daily dose (\(med.maximumDailyDosage)).",
                severity: "danger"
            ))
        }

        warnings = result
    }

    // MARK: - Save

    func save() async {
        guard let med = selectedMed, let dose = selectedDose else { return }
        isSaving = true
        successMessage = nil
        errorMessage = nil
        defer { isSaving = false }

        let log = MedicationLog(
            medicationName: med.genericName,
            dose: "\(dose) \(med.doseUnit)",
            reason: reason
        )
        do {
            try await SupabaseService.shared.logDose(log)
            await loadLogs()
            reason = ""
            selectedDose = nil
            warnings = []
            successMessage = "Dose logged successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func parseHours(from string: String) -> Double? {
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Double.init)
        return numbers.first
    }

    private func parseMaxDose(from string: String) -> Double? {
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Double.init)
        return numbers.first
    }
}

// MARK: - View

struct DoseLoggerView: View {
    @StateObject private var vm = DoseLoggerViewModel()

    var body: some View {
        NavigationStack {
            Form {
                logSection
                if !vm.warnings.isEmpty { warningSection }
                if vm.selectedMed != nil { saveSection }
                historySection
            }
            .navigationTitle("Dose Log")
            .task {
                await vm.loadMedications()
                await vm.loadLogs()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    // MARK: Sections

    private var logSection: some View {
        Section("Log a Dose") {
            Picker("Medication", selection: $vm.selectedMed) {
                Text("Select…").tag(Optional<Medication>.none)
                ForEach(vm.medications) { med in
                    Text(med.genericName).tag(Optional(med))
                }
            }
            .onChange(of: vm.selectedMed) { _, _ in
                vm.selectedDose = vm.selectedMed?.doses.first
                vm.computeWarnings()
            }

            if let med = vm.selectedMed {
                Picker("Dose", selection: $vm.selectedDose) {
                    Text("Select…").tag(Optional<Double>.none)
                    ForEach(med.doses, id: \.self) { d in
                        Text("\(d, specifier: "%.0f") \(med.doseUnit)").tag(Optional(d))
                    }
                }
                .onChange(of: vm.selectedDose) { _, _ in vm.computeWarnings() }
            }

            TextField("Reason (optional)", text: $vm.reason)
        }
    }

    private var warningSection: some View {
        Section("Warnings") {
            ForEach(vm.warnings) { w in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: w.severity == "danger" ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(w.severity == "danger" ? .red : w.severity == "warning" ? .orange : .blue)
                    Text(w.message)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            if let msg = vm.successMessage {
                Label(msg, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            Button(action: { Task { await vm.save() } }) {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Label("Log Dose", systemImage: "plus.circle.fill")
                }
            }
            .disabled(vm.selectedMed == nil || vm.selectedDose == nil || vm.isSaving)
        }
    }

    private var historySection: some View {
        Section("History") {
            if vm.isLoading {
                ProgressView()
            } else {
                if vm.logs.isEmpty {
                    Text("No logs yet.")
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Search history…", text: $vm.searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)

                    ForEach(vm.filteredLogs) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(log.medicationName).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(log.dose).font(.subheadline).foregroundStyle(.secondary)
                            }
                            if !log.reason.isEmpty {
                                Text(log.reason).font(.caption).foregroundStyle(.secondary)
                            }
                            if let ts = log.timestamp {
                                Text(ts).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DoseLoggerView()
}
