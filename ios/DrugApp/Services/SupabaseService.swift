import Foundation

/// Thin wrapper around the Supabase PostgREST REST API.
/// Replace the two constants below with your project's values.
actor SupabaseService {

    // MARK: - Configuration (replace with your project values)
    private let supabaseURL = "https://<YOUR_PROJECT_ID>.supabase.co"
    private let supabaseKey = "<YOUR_ANON_KEY>"

    static let shared = SupabaseService()
    private init() {}

    // MARK: - Generic helpers

    private func endpoint(_ table: String, query: String = "") -> URL {
        let string = "\(supabaseURL)/rest/v1/\(table)\(query.isEmpty ? "" : "?\(query)")"
        return URL(string: string)!
    }

    private func baseRequest(url: URL, method: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        return req
    }

    private func get<T: Decodable>(_ table: String, query: String = "") async throws -> [T] {
        let req = baseRequest(url: endpoint(table, query: query), method: "GET")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([T].self, from: data)
    }

    private func post<T: Codable>(_ table: String, body: T) async throws {
        var req = baseRequest(url: endpoint(table), method: "POST")
        req.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Medication logs

    func fetchMedicationLogs() async throws -> [MedicationLog] {
        try await get("medication_logs", query: "order=timestamp.desc&limit=50")
    }

    func logDose(_ log: MedicationLog) async throws {
        try await post("medication_logs", body: log)
    }

    // MARK: - Symptom logs

    func fetchSymptomLogs() async throws -> [SymptomLog] {
        try await get("symptom_logs", query: "order=logged_at.desc&limit=100")
    }

    func logSymptom(_ log: SymptomLog) async throws {
        try await post("symptom_logs", body: log)
    }

    // MARK: - Thought records

    func fetchThoughtRecords() async throws -> [ThoughtRecord] {
        try await get("thought_records", query: "order=created_at.desc&limit=50")
    }

    func saveThoughtRecord(_ record: ThoughtRecord) async throws {
        try await post("thought_records", body: record)
    }
}
