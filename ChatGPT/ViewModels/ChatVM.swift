//
//  ChatVM.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import OpenAI
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

class ChatVM: ObservableObject {
    
    @Published var chat: AppChat?
    @Published var messages: [AppMessage] = []
    @Published var messageText: String = ""
    @Published var selectedModel: ChatModel = .gpt3_5_turbo
    
    @AppStorage("openai_api_key") var apiKey = ""
    
    let chatId: String
    
    let db = Firestore.firestore()
    
    init(chatId: String) {
        self.chatId = chatId
    }
    
    func fetchData() {
//        self.messages = [
//            AppMessage(id: "1", text: "Hi", role: .user, createdAt: Date()),
//            AppMessage(id: "2", text: "Hello", role: .assistant, createdAt: Date())
//        ]
        
        db.collection("chats").document(chatId).getDocument(as: AppChat.self) { result in
            switch result {
            case .success(let success):
                DispatchQueue.main.async {
                    self.chat = success
                }
            case .failure(let failure):
                print(failure)
            }
        }
        db.collection("chats").document(chatId).collection("messages").order(by: "createdAt").getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else { return }
            
            self.messages = documents.compactMap({ snapshot -> AppMessage? in
                do {
                    var message = try snapshot.data(as: AppMessage.self)
                    message.id = snapshot.documentID
                    return message
                } catch {
                    return nil
                }
            })
        }
    }
    
    func sendMessage() async throws {
        var newMessage = AppMessage(id: UUID().uuidString, text: messageText, role: .user)
        
        do {
            let documentRef = try storeMessage(message: newMessage)
            newMessage.id = documentRef.documentID
        } catch {
            print(error)
        }
        
        if messages.isEmpty {
            setupNewChat()
        }
        
        await MainActor.run { [newMessage] in
            messages.append(newMessage)
            messageText = ""
        }
        
        try await generateResponse(for: newMessage)
    }
    
    private func storeMessage(message: AppMessage) throws -> DocumentReference {
        return try db.collection("chats").document(chatId).collection("messages").addDocument(from: message)
    }
    
    private func setupNewChat() {
        db.collection("chats").document(chatId).updateData(["model": selectedModel.rawValue])
        DispatchQueue.main.async { [weak self] in
            self?.chat?.model = self?.selectedModel
        }
    }
    
    private func generateResponse(for message: AppMessage) async throws {
        let openAI = OpenAI(apiToken: apiKey)
        
        // Convert messages to the expected format with proper role conversion
        let queryMessages: [ChatQuery.ChatCompletionMessageParam] = messages.compactMap { appMessage in
            // Convert MessageRole to ChatQuery.ChatCompletionMessageParam.Role
            guard let role = ChatQuery.ChatCompletionMessageParam.Role(rawValue: appMessage.role.rawValue) else {
                return nil // Skip invalid roles
            }
            return ChatQuery.ChatCompletionMessageParam(role: role, content: appMessage.text)
        }
        
        // Prepare the query
        let query = ChatQuery(messages: queryMessages, model: chat?.model?.model ?? .gpt3_5Turbo)
        
        for try await result in openAI.chatsStream(query: query) {
            guard let newText = result.choices.first?.delta.content else { continue }
            
            await MainActor.run {
                if let lastMessage = self.messages.last, lastMessage.role != .user {
                    messages[messages.count - 1].text += newText
                } else {
                    let newMessage = AppMessage(id: result.id, text: newText, role: .assistant)
                    messages.append(newMessage)
                }
            }
        }
        
        if let lastMessage = messages.last {
            _ = try storeMessage(message: lastMessage)
        }
    }



    
//    private func generateResponse(for message: AppMessage) async throws {
//        let openAI = OpenAI(apiToken: apiKey)
//        let queryMessages = messages.map { appMessage in
//            Chat(role: appMessage.role.rawValue, content: appMessage.text)
//        }
//        let query = ChatQuery(messages: queryMessages, model: chat?.model?.model ?? .gpt3_5Turbo)
//        
//        for try await result in openAI.chatsStream(query: query) {
//            guard let newtext = result.choices.first?.delta.content else { continue }
//            await MainActor.run {
//                if let lastMessage = self.messages.last, lastMessage.role != .user {
//                    messages[messages.count - 1].text += newtext
//                } else {
//                    let newMessage = AppMessage(id: result.id, text: newtext, role: .assistant)
//                    messages.append(newMessage)
//                }
//            }
//        }
//        if let lastMessage = messages.last {
//            _ = try storeMessage(message: lastMessage)
//        }
//    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

struct AppMessage: Identifiable, Hashable, Codable {
    @DocumentID var id: String?
    var text: String
    let role: MessageRole
    let createdAt: FirestoreDate = FirestoreDate()
}

struct Chat: Codable {
    let role: String
    let content: String
}

enum Role: String, Codable {
    case user
    case assistant
    case system
}
