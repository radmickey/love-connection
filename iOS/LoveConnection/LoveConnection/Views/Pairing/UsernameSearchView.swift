import SwiftUI

struct UsernameSearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var isSearching = false
    @State private var foundUser: User?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Search for your partner")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                TextField("Enter username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        searchUser()
                    }
                    .padding(.horizontal)

                if isSearching {
                    ProgressView()
                        .padding()
                } else if let foundUser = foundUser {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(foundUser.username)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Button(action: {
                            sendPairRequest()
                        }) {
                            Text("Send Pair Request")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func searchUser() {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }

        isSearching = true
        errorMessage = nil
        foundUser = nil

        Task {
            do {
                let user = try await APIService.shared.searchUser(username: username)
                foundUser = user
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
            isSearching = false
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

