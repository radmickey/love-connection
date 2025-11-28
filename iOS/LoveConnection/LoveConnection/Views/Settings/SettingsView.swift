import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend Information") {
                    Text("Backend URL")
                        .font(.headline)
                    Text(Config.shared.baseURL)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    #if DEBUG
                    Text("Debug Build")
                        .font(.caption)
                        .foregroundColor(.orange)
                    #else
                    Text("Production Build")
                        .font(.caption)
                        .foregroundColor(.green)
                    #endif
                }

                Section("Account") {
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Label("Profile", systemImage: "person.circle")
                            Spacer()
                            if let user = appState.currentUser {
                                Text(user.username)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(appState)
            }
        }
    }
}
