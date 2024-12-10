//
//  ChatListView.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import SwiftUI

struct ChatListView: View {
    
    @StateObject var viewModel = ChatListVM()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading, .none:
                Text("Loading chats...")
            case .noResults:
                Text("No chats.")
            case .resultsFound:
                List {
                    ForEach(viewModel.chats) { chat in
                        NavigationLink(value: chat.id) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(chat.topic ?? "New Chat")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(chat.model?.rawValue ?? "")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(chat.model?.tintColor ?? .white)
                                        .padding(6)
                                        .background((chat.model?.tintColor ?? .white).opacity(0.1))
                                        .clipShape(Capsule(style: .continuous))
                                }
                                Text(chat.lastMessageTimeAgo)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.deleteChat(chat: chat)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showProfile()
                } label: {
                    Image(systemName: "person")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        do {
                            let chatID = try await viewModel.createChat(user: appState.currentUser?.uid)
                            appState.navigationPAth.append(chatID)
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingProfileView) {
            ProfileView()
        }
        .navigationDestination(for: String.self) { chatId in
            ChatView(viewModel: .init(chatId: chatId))
        }
        .onAppear {
            if viewModel.loadingState == .none {
                viewModel.fetchData(user: appState.currentUser?.uid)
            }
        }
    }
}

#Preview {
    ChatListView()
}
