# Drug App — iOS (SwiftUI)

This directory contains a native iOS version of the Drug Web App, built with **SwiftUI** and targeting **iOS 16+**.

It mirrors all four features of the web app:

| Web page | iOS view |
|---|---|
| `index.html` | Medication Reference (`MedicationListView`) |
| `logger.html` | Dose Logger (`DoseLoggerView`) |
| `symptom_logger.html` | Symptom Logger (`SymptomLoggerView`) |
| `socratic.html` | Socratic / CBT Tool (`SocraticView`) |

---

## Prerequisites

| Tool | Version |
|---|---|
| Xcode | 15.0 + |
| iOS deployment target | 16.0 + |
| Swift | 5.9 + |

No third-party Swift packages are required. The app uses only Apple frameworks (`SwiftUI`, `Foundation`, `Combine`) and calls the existing **Supabase REST API** directly over HTTPS.

---

## Setup

### 1. Create an Xcode project

1. Open **Xcode → File → New → Project**.
2. Choose **iOS → App**.
3. Set:
   - **Product Name:** `DrugApp`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Bundle Identifier:** your choice (e.g. `com.yourname.DrugApp`)
4. Save the project **inside** this `ios/` folder so the generated `.xcodeproj` sits next to `DrugApp/`.

### 2. Add source files

Add all `.swift` files from `DrugApp/` (and its sub-folders) to the Xcode project.  
The folder hierarchy to replicate in the project navigator:

```
DrugApp/
├── DrugAppApp.swift
├── ContentView.swift
├── Models/
│   ├── Medication.swift
│   └── SupabaseModels.swift
├── Services/
│   ├── MedlistService.swift
│   └── SupabaseService.swift
└── Views/
    ├── MedicationListView.swift
    ├── MedicationDetailView.swift
    ├── DoseLoggerView.swift
    ├── SymptomLoggerView.swift
    └── SocraticView.swift
```

### 3. Bundle medlist.json

Copy `medlist.json` from the repository root into the Xcode project and make sure it is added to the **target's bundle resources** (tick "Add to target: DrugApp" when prompted). A symlink is not sufficient — Xcode needs the actual file.

### 4. Configure Supabase credentials

Open `Services/SupabaseService.swift` and replace the two placeholder constants at the top of the file:

```swift
private let supabaseURL = "https://<YOUR_PROJECT_ID>.supabase.co"
private let supabaseKey = "<YOUR_ANON_KEY>"
```

These values are the same ones already embedded in `logger.html`, `symptom_logger.html`, and `socratic.html`.

### 5. Build & run

Select any **iPhone simulator** (or a real device) and press **⌘R**.

---

## Architecture overview

```
┌─────────────┐     loads      ┌──────────────────┐
│ MedlistService│ ──────────▶  │ medlist.json (bundle) │
└─────────────┘                └──────────────────┘

┌─────────────┐   HTTP REST   ┌──────────────────┐
│SupabaseService│ ──────────▶  │ Supabase PostgREST │
└─────────────┘                └──────────────────┘
        ▲  ▲  ▲
        │  │  │
┌──────────────────────────────────┐
│          SwiftUI Views           │
│  MedicationList / DoseLogger /   │
│  SymptomLogger / SocraticView    │
└──────────────────────────────────┘
```

All network calls are made with the native `URLSession` async/await API — no third-party networking libraries are needed.

---

## Supabase tables

The iOS app reads from and writes to the same Supabase project as the web app.  
See `SUPABASE_SETUP.md` in the repository root for the full SQL schema.

| Table | Used by |
|---|---|
| `medication_logs` | DoseLoggerView |
| `blood_pressure_logs` | *(future)* |
| `symptom_logs` | SymptomLoggerView |
| `thought_records` | SocraticView |

---

## Notes & known limitations

- **No offline cache** — the app requires an active internet connection to read/write logs.
- **Anon key is client-visible** — same as the web app. Consider adding Row Level Security policies in Supabase before distributing the app.
- The symptom library (`comprehensive_master_symptom_library.json`) is not yet bundled for symptom selection. `SymptomLoggerView` uses a free-text field as a placeholder until the JSON is added as a bundle resource.
