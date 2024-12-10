//
//  ChatListVM.swift
//  ChatGPT
//
//  Created by Anubhav Tomar on 09/12/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import OpenAI

class ChatListVM: ObservableObject {
    
    @Published var chats: [AppChat] = []
    @Published var loadingState: ChatListState = .none
    @Published var isShowingProfileView = false
    
    let db = Firestore.firestore()
    
    func fetchData(user: String?) {
//        self.chats = [
//            AppChat(id: "1", topic: "Some topic", model: .gpt3_5_turbo, lastMessageSent: Date(), owner: "123"),
//            AppChat(id: "2", topic: "Some other topic", model: .gpt4, lastMessageSent: Date(), owner: "123")
//        ]
//        self.loadingState = .resultsFound
        
        if loadingState == .none {
            loadingState = .loading
            db.collection("chats").whereField("owner", isEqualTo: user ?? "").addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self, let documents = querySnapshot?.documents, !documents.isEmpty else {
                    self?.loadingState = .noResults
                    return
                }
                
                self.chats = documents.compactMap({ snapshot -> AppChat? in
                    return try? snapshot.data(as: AppChat.self)
                })
                .sorted(by: { $0.lastMessageSent > $1.lastMessageSent })
                self.loadingState = .resultsFound
            }
        }
    }
    
    func createChat(user: String?) async throws -> String {
        let document = try await db.collection("chats").addDocument(data: ["lastMessageSent": Date(), "owner": user ?? ""])
        return document.documentID
    }
    
    func showProfile() {
        isShowingProfileView = true
    }
    
    func deleteChat(chat: AppChat) {
        guard let id = chat.id else { return }
        
        // Explicitly calling Firestore's delete method
        let documentReference = db.collection("chats").document(id)
        
        documentReference.delete() { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Document successfully deleted!")
            }
        }
    }
    
//    func deleteChat(chat: AppChat) {
//        guard let id = chat.id else { return }
//        db.collection("chats").document(id).delete()
//    }
}

enum ChatListState {
    case none
    case loading
    case noResults
    case resultsFound
}

struct AppChat: Codable, Identifiable {
    @DocumentID var id: String?
    let topic: String?
    var  model: ChatModel?
    let lastMessageSent: FirestoreDate
    let owner: String
    
    var lastMessageTimeAgo: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: lastMessageSent.date, to: now)
        
        let timeUnits: [(value: Int?, unit: String)] = [
            (components.year, "year"),
            (components.month, "month"),
            (components.day, "day"),
            (components.hour, "hour"),
            (components.minute, "minute"),
            (components.second, "second")
        ]
        
        for timeUnit in timeUnits {
            if let value = timeUnit.value, value > 0 {
                return "\(value) \(timeUnit.unit)\(value == 1 ? "" : "s") ago"
            }
        }
        return "just now"
    }
}

enum ChatModel: String, Codable, Hashable, CaseIterable {
    case gpt3_5_turbo = "GPT 3.5 Turbo"
    case gpt4 = "GPT 4"
    
    var tintColor: Color {
        switch self {
        case .gpt3_5_turbo:
            return .green
        case .gpt4:
            return .purple
        }
    }
    
    var model: Model {
        switch self {
        case .gpt3_5_turbo:
            return .gpt3_5Turbo
        case .gpt4:
            return .gpt4
        }
    }
}

struct FirestoreDate: Codable, Hashable, Comparable {
    static func < (lhs: FirestoreDate, rhs: FirestoreDate) -> Bool {
        lhs.date < rhs.date
    }
    
    var date: Date
    
    init(_ date: Date = Date()) {
        self.date = date
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let timeStamp = try container.decode(Timestamp.self)
        date = timeStamp.dateValue()
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let timeStamp = Timestamp(date: date)
        try container.encode(timeStamp)
    }
}
