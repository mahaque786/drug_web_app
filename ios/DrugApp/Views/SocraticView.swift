import SwiftUI

// MARK: - Question sets (mirrors socratic.html)

private let anxietyQuestions: [String] = [
    "What is the worst-case scenario you're imagining?",
    "If the worst case happened, how would you cope with it?",
    "What would be the best-case outcome?",
    "What is the most realistic outcome?",
    "How would you cope if the realistic outcome occurred?"
]

private let negativeThoughtQuestions: [String] = [
    "What evidence supports this thought?",
    "What evidence contradicts this thought?",
    "What alternative explanations are there?",
    "Are you catastrophizing or using all-or-nothing thinking?",
    "What would you tell a friend who had this same thought?",
    "What is the best outcome you could hope for?",
    "What is the most realistic outcome?",
    "How does believing this thought help or hurt you?",
    "Are you taking this situation personally when it's not entirely your fault?",
    "Are you ignoring evidence that contradicts this thought?",
    "What cognitive distortions might be at play (e.g. mind-reading, fortune-telling)?",
    "How important will this feel in five years?",
    "What actions could you take to improve the situation?",
    "What is one small step you could take right now?"
]

// MARK: - ViewModel

@MainActor
class SocraticViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case anxiety       = "Anxiety & Worst-Case Thinking"
        case negativeThought = "Specific Negative Thought"
        var id: String { rawValue }
    }

    @Published var mode: Mode = .anxiety
    @Published var situation = ""
    @Published var automaticThought = ""
    @Published var answers: [String] = []
    @Published var currentStep = 0  // 0 = setup, 1…N = questions
    @Published var records: [ThoughtRecord] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showRecords = false

    var questions: [String] {
        mode == .anxiety ? anxietyQuestions : negativeThoughtQuestions
    }

    var progress: Double {
        guard currentStep > 0 else { return 0 }
        return Double(currentStep) / Double(questions.count)
    }

    var currentQuestion: String? {
        guard currentStep > 0, currentStep <= questions.count else { return nil }
        return questions[currentStep - 1]
    }

    var isFinished: Bool { currentStep > questions.count }

    func startSession() {
        answers = Array(repeating: "", count: questions.count)
        currentStep = 1
    }

    func next() {
        guard currentStep <= questions.count else { return }
        currentStep += 1
    }

    func back() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }

    func reset() {
        situation = ""
        automaticThought = ""
        answers = []
        currentStep = 0
    }

    func loadRecords() async {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await SupabaseService.shared.fetchThoughtRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        let pairs = zip(questions, answers).map { QAPair(question: $0, answer: $1) }
        let record = ThoughtRecord(
            mode: mode.rawValue,
            situation: situation,
            automaticThought: automaticThought,
            qaPairs: pairs
        )
        do {
            try await SupabaseService.shared.saveThoughtRecord(record)
            await loadRecords()
            reset()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View

struct SocraticView: View {
    @StateObject private var vm = SocraticViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    disclaimer

                    if vm.currentStep == 0 {
                        setupSection
                    } else if vm.isFinished {
                        reviewSection
                    } else {
                        questionSection
                    }
                }
                .padding()
            }
            .navigationTitle("Socratic")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(vm.showRecords ? "Hide Records" : "Saved Records") {
                        vm.showRecords.toggle()
                        if vm.showRecords { Task { await vm.loadRecords() } }
                    }
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: Disclaimer

    private var disclaimer: some View {
        Label("This tool is for journaling only. If you are in crisis, please contact a mental health professional or call/text 988.", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(10)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Setup

    private var setupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a mode")
                .font(.headline)

            ForEach(SocraticViewModel.Mode.allCases) { mode in
                Button(action: { vm.mode = mode }) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.subheadline)
                        Spacer()
                        if vm.mode == mode {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(vm.mode == mode ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Text("Triggering situation")
                .font(.subheadline.weight(.medium))
            TextEditor(text: $vm.situation)
                .frame(height: 80)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Automatic thought")
                .font(.subheadline.weight(.medium))
            TextEditor(text: $vm.automaticThought)
                .frame(height: 80)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: vm.startSession) {
                Label("Begin", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.situation.trimmingCharacters(in: .whitespaces).isEmpty ||
                      vm.automaticThought.trimmingCharacters(in: .whitespaces).isEmpty)

            if vm.showRecords { savedRecordsSection }
        }
    }

    // MARK: Question

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProgressView(value: vm.progress)
                .tint(.blue)

            Text("Question \(vm.currentStep) of \(vm.questions.count)")
                .font(.caption).foregroundStyle(.secondary)

            if let q = vm.currentQuestion {
                Text(q)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: Binding(
                    get: { vm.answers.indices.contains(vm.currentStep - 1) ? vm.answers[vm.currentStep - 1] : "" },
                    set: { if vm.answers.indices.contains(vm.currentStep - 1) { vm.answers[vm.currentStep - 1] = $0 } }
                ))
                .frame(height: 120)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                if vm.currentStep > 1 {
                    Button("Back", action: vm.back).buttonStyle(.bordered)
                }
                Spacer()
                Button(vm.currentStep == vm.questions.count ? "Review" : "Next", action: vm.next)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review")
                .font(.headline)

            ForEach(Array(zip(vm.questions, vm.answers).enumerated()), id: \.offset) { idx, pair in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Q\(idx + 1): \(pair.0)")
                        .font(.subheadline.weight(.medium))
                    Text(pair.1.isEmpty ? "—" : pair.1)
                        .font(.subheadline)
                        .foregroundStyle(pair.1.isEmpty ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button("Back", action: vm.back).buttonStyle(.bordered)
                Spacer()
                Button(action: { Task { await vm.save() } }) {
                    if vm.isSaving { ProgressView() }
                    else { Label("Save Record", systemImage: "icloud.and.arrow.up") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isSaving)
            }

            Button("Start Over", role: .destructive, action: vm.reset)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Saved records

    private var savedRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Saved Records")
                .font(.headline)

            if vm.isLoading {
                ProgressView()
            } else if vm.records.isEmpty {
                Text("No saved records.").foregroundStyle(.secondary)
            } else {
                ForEach(vm.records) { rec in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rec.mode).font(.caption.weight(.semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                            if let ts = rec.createdAt {
                                Text(ts).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Text(rec.situation).font(.subheadline).lineLimit(2)
                        Text(rec.automaticThought).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    SocraticView()
}
