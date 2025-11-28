import SwiftUI

struct InviteLinkView: View {
    @Environment(\.dismiss) var dismiss
    @State private var inviteLink: String?
    @State private var username: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCopiedAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let inviteLink = inviteLink, let username = username {
                    VStack(spacing: 24) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Your Invite Link")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Share this link with your partner to connect")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        VStack(spacing: 16) {
                            Text(inviteLink)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)

                            Button(action: {
                                UIPasteboard.general.string = inviteLink
                                showCopiedAlert = true
                            }) {
                                Label("Copy Link", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            ShareLink(item: inviteLink) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }
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

                        Button("Retry") {
                            loadInviteLink()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Invite Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Link copied to clipboard")
            }
            .onAppear {
                loadInviteLink()
            }
        }
    }

    private func loadInviteLink() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.generateInviteLink()
                inviteLink = result.link
                username = result.username
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
            isLoading = false
        }
    }
}

