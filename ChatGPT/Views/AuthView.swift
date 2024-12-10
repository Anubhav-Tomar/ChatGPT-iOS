//
//  AuthView.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import SwiftUI

struct AuthView: View {
    
    @ObservedObject var viewModel: AuthVM = AuthVM()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("ChatGPT")
            
            TextField("Email", text: $viewModel.emailText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .textInputAutocapitalization(.never)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if viewModel.isPasswordIsVisible {
                SecureField("Password", text: $viewModel.passwordText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .textInputAutocapitalization(.never)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button {
                    viewModel.authenticate(appState: appState)
                } label: {
                    Text(viewModel.userExists ? "Login" : "Create User")
                }
                .padding()
                .foregroundStyle(.white)
                .background(Color.blue)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
}

#Preview {
    AuthView()
}
