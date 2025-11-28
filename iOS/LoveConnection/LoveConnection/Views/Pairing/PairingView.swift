import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingQRScanner = false
    @State private var showingQRCode = false

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

                Text("Scan your partner's QR code or share yours to create a connection")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    Button(action: { showingQRScanner = true }) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { showingQRCode = true }) {
                        Label("Show My QR Code", systemImage: "qrcode")
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
            .sheet(isPresented: $showingQRScanner) {
                QRScannerView()
            }
            .sheet(isPresented: $showingQRCode) {
                QRCodeDisplayView()
            }
        }
    }
}

