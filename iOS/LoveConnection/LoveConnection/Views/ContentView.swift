//
//  ContentView.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                if appState.currentPair != nil {
                    MainTabView()
                } else {
                    PairingView()
                }
            } else {
                LoginView()
            }
        }
        .task {
            appState.checkAuthenticationStatus()
        }
    }
}

