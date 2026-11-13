import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Today") { Text("25 min · Deep work") }
            }
            .navigationTitle("Focus")
        }
    }
}
