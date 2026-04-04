import Foundation

/// Loads and caches the bundled medlist.json file.
@MainActor
class MedlistService: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard medications.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        guard let url = Bundle.main.url(forResource: "medlist", withExtension: "json") else {
            errorMessage = "medlist.json not found in app bundle. Make sure it is added as a bundle resource in Xcode."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(MedList.self, from: data)
            medications = decoded.medications
        } catch {
            errorMessage = "Failed to parse medlist.json: \(error.localizedDescription)"
        }
    }
}
