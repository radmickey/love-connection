//
//  LoveConnectionApp.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import SwiftUI
import UIKit

@main
struct LoveConnectionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    init() {
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            #if !targetEnvironment(simulator)
            NotificationService.shared.registerForRemoteNotifications()
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

