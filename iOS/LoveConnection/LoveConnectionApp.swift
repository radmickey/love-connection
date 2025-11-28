//
//  LoveConnectionApp.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import SwiftUI

@main
struct LoveConnectionApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

