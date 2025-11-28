import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutAlert = false
    
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
                    if let user = appState.currentUser {
                        Text("Username: \(user.username)")
                        if let email = user.email {
                            Text("Email: \(email)")
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Logout", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}
