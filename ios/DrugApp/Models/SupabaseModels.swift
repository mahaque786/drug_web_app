import Foundation

// MARK: - Medication log (medication_logs table)

struct MedicationLog: Codable, Identifiable {
    var id: Int?
    var timestamp: String?
    let medicationName: String
    let dose: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case id, timestamp, reason
        case medicationName = "medication_name"
        case dose
    }
}

// MARK: - Symptom log (symptom_logs table)

struct SymptomLog: Codable, Identifiable {
    var id: Int?
    var loggedAt: String?
    let symptom: String
    let system: String
    let presence: String          // "Present" | "Absent" | "Unsure"
    let severity: Int             // 0–4
    let frequency: String         // "Never" | "Rarely" | "Sometimes" | "Often" | "Constantly"
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, symptom, system, presence, severity, frequency, notes
        case loggedAt = "logged_at"
    }
}

// MARK: - Thought record (thought_records table)

struct QAPair: Codable {
    let question: String
    let answer: String
}

struct ThoughtRecord: Codable, Identifiable {
    var id: Int?
    var createdAt: String?
    let mode: String              // "anxiety" | "negative_thought"
    let situation: String
    let automaticThought: String
    let qaPairs: [QAPair]

    enum CodingKeys: String, CodingKey {
        case id, mode, situation
        case createdAt      = "created_at"
        case automaticThought = "automatic_thought"
        case qaPairs        = "qa_pairs"
    }
}
