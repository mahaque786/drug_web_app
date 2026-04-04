import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MedicationListView()
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }

            DoseLoggerView()
                .tabItem {
                    Label("Dose Log", systemImage: "clock.fill")
                }

            SymptomLoggerView()
                .tabItem {
                    Label("Symptoms", systemImage: "heart.text.square.fill")
                }

            SocraticView()
                .tabItem {
                    Label("Socratic", systemImage: "brain.head.profile")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
