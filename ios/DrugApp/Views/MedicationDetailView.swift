import SwiftUI

/// Full detail view for a single medication — mirrors the expanded card in index.html.
struct MedicationDetailView: View {
    let medication: Medication

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                headerSection

                Divider()

                // Dosing
                SectionCard(title: "Dosing") {
                    InfoRow(label: "Available doses",     value: medication.doses.map { "\($0) \(medication.doseUnit)" }.joined(separator: ", "))
                    InfoRow(label: "Max daily dose",      value: medication.maximumDailyDosage)
                    InfoRow(label: "Min time between",    value: medication.timeRequiredBetweenDoses)
                    if let admin = medication.administration {
                        InfoRow(label: "Administration", value: admin)
                    }
                }

                // Pharmacokinetics
                SectionCard(title: "Pharmacokinetics") {
                    InfoRow(label: "Time to peak (Tmax)", value: medication.timeToMaxConcentration)
                    InfoRow(label: "Half-life",           value: medication.halfLife)
                    if let dur = medication.durationOfAction {
                        InfoRow(label: "Duration of action", value: dur)
                    }
                    if let met = medication.activeMetabolites {
                        InfoRow(label: "Active metabolites", value: met)
                    }
                    if let metHL = medication.halfLifeOfActiveMetabolites {
                        InfoRow(label: "Metabolite half-life", value: metHL)
                    }
                }

                // Mechanism of action
                SectionCard(title: "Mechanism of Action") {
                    Text(medication.mechanismOfAction)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Indications
                if !medication.indication.onLabel.isEmpty {
                    SectionCard(title: "On-Label Indications") {
                        TagCloud(tags: medication.indication.onLabel, color: .blue)
                    }
                }
                if !medication.indication.offLabel.isEmpty {
                    SectionCard(title: "Off-Label Uses") {
                        TagCloud(tags: medication.indication.offLabel, color: .purple)
                    }
                }

                // Interactions
                if !medication.interactions.isEmpty {
                    SectionCard(title: "Drug Interactions") {
                        ForEach(medication.interactions) { ix in
                            InteractionRow(interaction: ix)
                        }
                    }
                }

                // Citations
                if !medication.citations.isEmpty {
                    SectionCard(title: "Citations") {
                        ForEach(medication.citations) { c in
                            Label(c.title, systemImage: "doc.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(medication.genericName)
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medication.genericName)
                .font(.largeTitle.bold())
            if !medication.brandNames.isEmpty {
                Text(medication.brandNames.joined(separator: " · "))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Supporting views

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.blue)
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TagCloud: View {
    let tags: [String]
    let color: Color

    var body: some View {
        // Simple wrapping layout using a flow-style grid
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct InteractionRow: View {
    let interaction: DrugInteraction

    private var badgeColor: Color {
        switch interaction.severity.lowercased() {
        case "lethal":   return .red
        case "severe":   return .orange
        case "moderate": return .yellow
        case "mild":     return .blue
        default:         return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(interaction.drug)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(interaction.severity.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(badgeColor.opacity(0.2))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
            }
            Text(interaction.interaction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Simple flow layout

/// A simple left-to-right wrapping layout for tags.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentY += rowHeight + spacing
                totalHeight = max(totalHeight, currentY)
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width - bounds.minX > maxWidth, currentX > bounds.minX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        MedicationDetailView(medication: Medication(
            genericName: "Methylphenidate",
            brandNames: ["Ritalin", "Concerta"],
            indication: Indication(onLabel: ["ADHD"], offLabel: ["Narcolepsy"]),
            doses: [5, 10, 20],
            doseUnit: "mg",
            maximumDailyDosage: "60 mg/day",
            timeRequiredBetweenDoses: "4 hours",
            mechanismOfAction: "Blocks reuptake of dopamine and norepinephrine.",
            timeToMaxConcentration: "1–2 hours",
            halfLife: "2–3 hours",
            durationOfAction: "4–6 hours",
            activeMetabolites: nil,
            halfLifeOfActiveMetabolites: nil,
            interactions: [],
            citations: [],
            administration: nil
        ))
    }
}
