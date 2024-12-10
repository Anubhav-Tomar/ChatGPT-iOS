//
//  AuthVM.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import Foundation

class AuthVM: ObservableObject {
    @Published var emailText: String = ""
    @Published var passwordText: String = ""
    
    @Published var isLoading = false
    @Published var isPasswordIsVisible = false
    @Published var userExists = false
    
    let authService = AuthService()

    func authenticate(appState: AppState) {
        isLoading = true
        Task {
            do {
                if isPasswordIsVisible {
                    let result = try await authService.login(email: emailText, password: passwordText, userExists: userExists)
                    await MainActor.run {
                        guard let result = result else { return }
                        appState.currentUser = result.user
                    }
                } else {
                    userExists = try await authService.checkUserExists(email: emailText)
                    isPasswordIsVisible = true
                }
                isLoading = false
            } catch {
                print(error)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
