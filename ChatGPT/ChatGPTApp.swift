//
//  ChatGPTApp.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import SwiftUI

@main
struct ChatGPTApp: App {
    
    @ObservedObject var appState: AppState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                NavigationStack(path: $appState.navigationPAth) {
                    ChatListView()
                        .environmentObject(appState)
                }
            } else {
                AuthView()
                    .environmentObject(appState)
            }
        }
    }
}
