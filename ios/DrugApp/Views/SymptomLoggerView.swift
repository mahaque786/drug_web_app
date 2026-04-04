import SwiftUI

// MARK: - Data

private let bodySystems: [String] = [
    "General/Constitutional", "Pain", "Skin", "Eyes", "ENT",
    "Respiratory", "Cardiovascular", "Gastrointestinal", "Liver",
    "Urinary", "Reproductive", "Breast", "Musculoskeletal",
    "Neurologic", "Cognitive/Sleep", "Psychiatric", "Endocrine",
    "Hematologic", "Autonomic", "Pediatric"
]

private let presenceOptions  = ["Present", "Absent", "Unsure"]
private let frequencyOptions = ["Never", "Rarely", "Sometimes", "Often", "Constantly"]

// Per-symptom detail being built up during the wizard
private struct SymptomDetail: Identifiable {
    let id = UUID()
    var symptom: String
    var system: String
    var presence: String = "Present"
    var severity: Int = 2
    var frequency: String = "Sometimes"
    var notes: String = ""
}

// MARK: - ViewModel

@MainActor
class SymptomLoggerViewModel: ObservableObject {
    // Wizard state
    @Published var step = 1
    @Published var selectedSystems: Set<String> = []
    @Published var symptomInput = ""
    @Published var symptomList: [String] = []
    @Published var details: [SymptomDetail] = []

    // History
    @Published var history: [SymptomLog] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    var filteredHistory: [SymptomLog] {
        guard !searchText.isEmpty else { return history }
        let q = searchText.lowercased()
        return history.filter {
            $0.symptom.lowercased().contains(q) ||
            $0.system.lowercased().contains(q)
        }
    }

    func addSymptom() {
        let trimmed = symptomInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !symptomList.contains(trimmed) else { return }
        symptomList.append(trimmed)
        symptomInput = ""
        syncDetails()
    }

    func removeSymptom(_ symptom: String) {
        symptomList.removeAll { $0 == symptom }
        details.removeAll { $0.symptom == symptom }
    }

    private func syncDetails() {
        for sym in symptomList where !details.contains(where: { $0.symptom == sym }) {
            let system = selectedSystems.first ?? "General/Constitutional"
            details.append(SymptomDetail(symptom: sym, system: system))
        }
    }

    func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        do {
            history = try await SupabaseService.shared.fetchSymptomLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            for d in details {
                let log = SymptomLog(
                    symptom: d.symptom,
                    system: d.system,
                    presence: d.presence,
                    severity: d.severity,
                    frequency: d.frequency,
                    notes: d.notes.isEmpty ? nil : d.notes
                )
                try await SupabaseService.shared.logSymptom(log)
            }
            successMessage = "\(details.count) symptom(s) logged."
            await loadHistory()
            reset()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        step = 1
        selectedSystems = []
        symptomInput = ""
        symptomList = []
        details = []
    }
}

// MARK: - View

struct SymptomLoggerView: View {
    @StateObject private var vm = SymptomLoggerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                Group {
                    switch vm.step {
                    case 1: step1
                    case 2: step2
                    case 3: step3
                    case 4: step4
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                navButtons
            }
            .navigationTitle("Symptom Log")
            .task { await vm.loadHistory() }
        }
    }

    // MARK: Progress bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...4, id: \.self) { i in
                Capsule()
                    .fill(i <= vm.step ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: Step 1 — select systems

    private var step1: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                ForEach(bodySystems, id: \.self) { sys in
                    Button(action: {
                        if vm.selectedSystems.contains(sys) {
                            vm.selectedSystems.remove(sys)
                        } else {
                            vm.selectedSystems.insert(sys)
                        }
                    }) {
                        Text(sys)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(vm.selectedSystems.contains(sys) ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(vm.selectedSystems.contains(sys) ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: Step 2 — enter symptoms

    private var step2: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add symptoms for: \(vm.selectedSystems.sorted().joined(separator: ", "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            HStack {
                TextField("Type a symptom…", text: $vm.symptomInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { vm.addSymptom() }
                Button("Add", action: vm.addSymptom)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if vm.symptomList.isEmpty {
                Spacer()
                Text("No symptoms added yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(vm.symptomList, id: \.self) { sym in
                        HStack {
                            Text(sym)
                            Spacer()
                            Button(role: .destructive, action: { vm.removeSymptom(sym) }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.top)
    }

    // MARK: Step 3 — details for each symptom

    private var step3: some View {
        List($vm.details) { $detail in
            Section(detail.symptom) {
                Picker("Presence", selection: $detail.presence) {
                    ForEach(presenceOptions, id: \.self) { Text($0) }
                }
                Stepper("Severity: \(detail.severity)/4", value: $detail.severity, in: 0...4)
                Picker("Frequency", selection: $detail.frequency) {
                    ForEach(frequencyOptions, id: \.self) { Text($0) }
                }
                TextField("Notes (optional)", text: $detail.notes)
            }
        }
    }

    // MARK: Step 4 — review & submit

    private var step4: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let err = vm.errorMessage {
                    Label(err, systemImage: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                }
                if let msg = vm.successMessage {
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Text("Review (\(vm.details.count) symptom(s))")
                    .font(.headline)

                ForEach(vm.details) { d in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(d.symptom).font(.subheadline.weight(.semibold))
                        Text("\(d.presence) · Severity \(d.severity)/4 · \(d.frequency)")
                            .font(.caption).foregroundStyle(.secondary)
                        if !d.notes.isEmpty {
                            Text(d.notes).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: { Task { await vm.submit() } }) {
                    if vm.isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("Submit Session", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isSaving || vm.details.isEmpty)

                Divider()

                Text("History")
                    .font(.headline)

                TextField("Search history…", text: $vm.searchText)
                    .textFieldStyle(.roundedBorder)

                if vm.history.isEmpty {
                    Text("No logs yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.filteredHistory) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.symptom).font(.subheadline.weight(.medium))
                                Text("\(log.system) · \(log.presence) · \(log.frequency)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let ts = log.loggedAt {
                                Text(ts).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: Nav buttons

    private var navButtons: some View {
        HStack {
            if vm.step > 1 {
                Button("Back") { vm.step -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if vm.step < 4 {
                Button("Next") { vm.step += 1 }
                    .buttonStyle(.borderedProminent)
                    .disabled((vm.step == 1 && vm.selectedSystems.isEmpty) || (vm.step == 2 && vm.symptomList.isEmpty))
            }
        }
        .padding()
        .background(Color(.systemBackground).shadow(.drop(radius: 2)))
    }
}

#Preview {
    SymptomLoggerView()
}
