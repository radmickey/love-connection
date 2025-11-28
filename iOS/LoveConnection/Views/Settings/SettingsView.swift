import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var backendURL: String = ""
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Backend Configuration") {
                    TextField("Backend URL", text: $backendURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    
                    Text("Current: \(Config.shared.baseURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Save URL") {
                        UserDefaults.standard.set(backendURL, forKey: "backend_url")
                    }
                    .disabled(backendURL.isEmpty)
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
            .onAppear {
                backendURL = UserDefaults.standard.string(forKey: "backend_url") ?? ""
            }
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

