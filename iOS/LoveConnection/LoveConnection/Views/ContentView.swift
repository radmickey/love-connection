//
//  ContentView.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingUsernameSearch = false
    @State private var usernameToAdd: String?

    var body: some View {
        Group {
            if appState.isCheckingAuth {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    ProgressView()
                }
            } else if appState.isAuthenticated {
                if appState.needsUsernameSetup {
                    UsernameInputView()
                        .onChange(of: appState.currentUser?.username) { username in
                            if let username = username, !username.isEmpty && username != "User" {
                                Task {
                                    appState.needsUsernameSetup = false
                                    await appState.loadCurrentPair()
                                    NotificationService.shared.sendDeviceTokenIfAuthenticated()
                                }
                            }
                        }
                } else {
                    MainTabView()
                        .sheet(isPresented: $showingUsernameSearch) {
                            if let username = usernameToAdd {
                                UsernameSearchViewWithUsername(username: username)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddPartnerByUsername"))) { notification in
                            if let username = notification.userInfo?["username"] as? String {
                                usernameToAdd = username
                                showingUsernameSearch = true
                            }
                        }
                }
            } else {
                LoginView()
            }
        }
    }
}

struct UsernameSearchViewWithUsername: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let username: String
    @State private var errorMessage: String?
    @State private var foundUser: User?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let foundUser = foundUser {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(foundUser.username)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Send a pair request to this user?")
                            .foregroundColor(.secondary)

                        Button(action: {
                            sendPairRequest()
                        }) {
                            Text("Send Pair Request")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Error")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                searchUser()
            }
        }
    }

    private func searchUser() {
        Task {
            do {
                let user = try await APIService.shared.searchUser(username: username)
                foundUser = user
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
        }
    }

    private func sendPairRequest() {
        guard let foundUser = foundUser else { return }

        Task {
            do {
                _ = try await APIService.shared.createPairRequest(username: foundUser.username)
                dismiss()
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
        }
    }
}

