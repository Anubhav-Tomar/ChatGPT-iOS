//
//  AppState.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

class AppState:ObservableObject {
    @Published var currentUser: User?
    @Published var navigationPAth = NavigationPath()
    
    var isLoggedIn: Bool {
        return currentUser != nil
    }
    
    init() {
        FirebaseApp.configure()
        
        if let currentUser = Auth.auth().currentUser {
            self.currentUser = currentUser
        }
    }
}
