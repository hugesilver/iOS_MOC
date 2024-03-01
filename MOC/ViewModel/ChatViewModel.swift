//
//  ChatViewModel.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ChatViewModel: ObservableObject {
    @Published var user: User?
    @Published var chatroom: ChatroomModel?
    private var joined_people: [String] = []
    @Published var firstChatDocument: MessageModel?
    @Published var lastChatDocument: DocumentSnapshot?
    
    private let limit: Int = 40
    
    @Published var messages: [MessageModel]?
    @Published var joinedUsers: [String: UserInfoModel] = [:]
    
    private let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            self.user = user
        }
    }
    
    func getChatroomData(docId: String) async {
        let ref = db.collection("chats").document(docId)
        
        ref.addSnapshotListener { querySnapshot, error in
            guard let document = querySnapshot else {
                print("No document")
                return
            }
            
            if document.exists {
                self.chatroom = ChatroomModel(id: document.documentID, data: document.data()!)
                
                Task {
                    await self.getUsersData(chatroomModel: ChatroomModel(id: document.documentID, data: document.data()!)!)
                }
            } else {
                print("ChatroomModel 변환 중 실패")
            }
        }
    }
    
    func getChatData(docId: String) async {
        let ref = db.collection("chats").document(docId).collection("chat").order(by: "time", descending: true).limit(to: limit)
        
        ref.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            if self.messages != nil {
                querySnapshot?.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        if let firstChat = documents.first, let firstChatModel = MessageModel(id: firstChat.documentID, data: firstChat.data()) {
                            self.firstChatDocument = firstChatModel
                            self.messages = [firstChatModel] + self.messages!
                        }
                    }
                    if (diff.type == .modified) {
                        // 변경 되었을 때의 코드
                    }
                    if (diff.type == .removed) {
                        // 삭제 되었을 때의 코드
                    }
                }
            } else {
                self.messages = documents.compactMap { document in
                    if document.exists {
                        return MessageModel(id: document.documentID, data: document.data())
                    } else {
                        print("ChatModel 변환 중 실패")
                        return nil
                    }
                }
                
                if documents.count >= self.limit {
                    self.lastChatDocument = documents.last
                } else {
                    self.lastChatDocument = nil
                }
            }
        }
    }
    
    func getMoreChatData(docId: String) async -> Bool {
        var ref = db.collection("chats").document(docId).collection("chat").order(by: "time", descending: true).limit(to: limit)
        
        if let lastChatDocument {
            ref = ref.start(afterDocument: lastChatDocument)
        }
        
        do {
            print("작동 중")
            let querySnapshot = try await ref.getDocuments()
            let documents = querySnapshot.documents 
            
            if !documents.isEmpty{
                let tempMessages = documents.compactMap { document in
                    if document.exists {
                        return MessageModel(id: document.documentID, data: document.data())
                    } else {
                        print("ChatModel 변환 중 실패")
                        return nil
                    }
                }
                
                if self.messages != nil {
                    self.messages = self.messages! + tempMessages
                } else {
                    self.messages = tempMessages
                }
                
                if documents.count >= limit {
                    self.lastChatDocument = documents.last
                } else {
                    self.lastChatDocument = nil
                }
                
                return true
            } else {
                self.lastChatDocument = nil
            }
        } catch {
            print("채팅 더 불러오기 중 오류: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func getUsersData(chatroomModel: ChatroomModel) async {
        for person in Array(Set(chatroomModel.joined_people).subtracting(Set(joined_people))) {
            let ref = db.collection("users").document(person)
            do {
                let document = try await ref.getDocument()
                
                if document.exists {
                    print("\(person)의 문서 불러오기 성공")
                    joinedUsers[person] = UserInfoModel(data: document.data()!)
                }
            } catch {
                print("\(person)의 문서 불러오기 실패")
            }
        }
        
        self.joined_people = chatroomModel.joined_people
    }
    
    func sendText(docId: String, text: String) async {
        if user != nil && !text.isEmpty {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmssSS"
            let dateString = formatter.string(from: date)
            
            let ref = db.collection("chats").document(docId).collection("chat").document("\(dateString)_\(user!.uid)")
            
            do {
                try await ref.setData([
                    "text": text,
                    "time": date,
                    "type": "text",
                    "uid": user!.uid,
                ])
            } catch {
                print("택스트 채팅 전송 중 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func sendImage(docId: String, image: UIImage) async {
        if user != nil {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmssSS"
            let dateString = formatter.string(from: date)
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("이미지 jpeg로 변환 중 오류")
                return
            }
            
            let ref = db.collection("chats").document(docId).collection("chat").document("\(dateString)_\(user!.uid)")
            let storageRef = Storage.storage().reference().child("chats/\(docId)/image_\(dateString)_\(user!.uid).jpg")
            
            storageRef.putData(imageData, metadata: nil) { _, _ in
                Task {
                    do {
                        let url: URL = try await storageRef.downloadURL()
                        try await ref.setData([
                            "image": url.absoluteString,
                            "time": date,
                            "type": "image",
                            "uid": self.user!.uid,
                        ])
                    } catch {
                        print("채팅 이미지 업로드 중 오류: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
