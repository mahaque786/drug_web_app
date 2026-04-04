import SwiftUI

/// Searchable list of all medications loaded from medlist.json.
/// Equivalent to index.html in the web app.
struct MedicationListView: View {
    @StateObject private var service = MedlistService()
    @State private var searchText = ""

    var filtered: [Medication] {
        guard !searchText.isEmpty else { return service.medications }
        let q = searchText.lowercased()
        return service.medications.filter { med in
            med.genericName.lowercased().contains(q) ||
            med.brandNames.joined(separator: " ").lowercased().contains(q) ||
            med.indication.onLabel.joined(separator: " ").lowercased().contains(q) ||
            med.indication.offLabel.joined(separator: " ").lowercased().contains(q) ||
            med.mechanismOfAction.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("Loading medications…")
                } else if let error = service.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    List(filtered) { med in
                        NavigationLink(destination: MedicationDetailView(medication: med)) {
                            MedicationRowView(medication: med)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Medications")
            .searchable(text: $searchText, prompt: "Search by name, indication, or MOA")
            .task { await service.load() }
        }
    }
}

// MARK: - Row

private struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medication.genericName)
                .font(.headline)
            if !medication.brandNames.isEmpty {
                Text(medication.brandNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !medication.indication.onLabel.isEmpty {
                Text(medication.indication.onLabel.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MedicationListView()
}
