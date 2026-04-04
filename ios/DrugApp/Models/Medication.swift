import Foundation

// MARK: - Top-level medlist.json structure

struct MedList: Decodable {
    let source: String
    let disclaimer: String
    let dateCompiled: String
    let medications: [Medication]

    enum CodingKeys: String, CodingKey {
        case source, disclaimer, medications
        case dateCompiled = "date_compiled"
    }
}

// MARK: - Individual medication

struct Medication: Decodable, Identifiable {
    var id: String { genericName }

    let genericName: String
    let brandNames: [String]
    let indication: Indication
    let doses: [Double]
    let doseUnit: String
    let maximumDailyDosage: String
    let timeRequiredBetweenDoses: String
    let mechanismOfAction: String
    let timeToMaxConcentration: String
    let halfLife: String
    let durationOfAction: String?
    let activeMetabolites: String?
    let halfLifeOfActiveMetabolites: String?
    let interactions: [DrugInteraction]
    let citations: [Citation]
    let administration: String?

    enum CodingKeys: String, CodingKey {
        case doses, indication, citations, administration
        case genericName                    = "generic_name"
        case brandNames                     = "brand_names"
        case doseUnit                       = "dose_unit"
        case maximumDailyDosage             = "maximum_daily_dosage"
        case timeRequiredBetweenDoses       = "time_required_between_doses"
        case mechanismOfAction              = "mechanism_of_action"
        case timeToMaxConcentration         = "time_to_max_concentration"
        case halfLife                       = "half_life"
        case durationOfAction               = "duration_of_action"
        case activeMetabolites              = "active_metabolites"
        case halfLifeOfActiveMetabolites    = "half_life_of_active_metabolites"
        case interactions                   = "interactions_with_other_drugs_on_this_list"
    }
}

// MARK: - Indication (on-label / off-label)

struct Indication: Decodable {
    let onLabel: [String]
    let offLabel: [String]

    enum CodingKeys: String, CodingKey {
        case onLabel  = "on_label"
        case offLabel = "off_label"
    }
}

// MARK: - Drug–drug interaction

struct DrugInteraction: Decodable, Identifiable {
    var id: String { drug }

    let drug: String
    let interaction: String
    let severity: String
}

// MARK: - Citation

struct Citation: Decodable, Identifiable {
    var id: String { title }

    let type: String
    let title: String
}

// MARK: - Severity helpers

extension DrugInteraction {
    var severityColor: String {
        switch severity.lowercased() {
        case "lethal":   return "red"
        case "severe":   return "orange"
        case "moderate": return "yellow"
        case "mild":     return "blue"
        default:         return "gray"
        }
    }
}
