import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingUsernameSearch = false
    @State private var showingInviteLink = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)

                Text("Connect with your partner")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Search for your partner by username or share your invite link")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    Button(action: { showingUsernameSearch = true }) {
                        Label("Search by Username", systemImage: "person.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { showingInviteLink = true }) {
                        Label("Share Invite Link", systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink(destination: PairRequestsView()) {
                        Label("Pair Requests", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Pairing")
            .sheet(isPresented: $showingUsernameSearch) {
                UsernameSearchView()
            }
            .sheet(isPresented: $showingInviteLink) {
                InviteLinkView()
            }
        }
    }
}

