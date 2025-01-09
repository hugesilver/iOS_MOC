//
//  ChatViewModel.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

@MainActor
class ChatViewModel: ObservableObject {
    enum ActiveAlert {
        case isTextError, isImageError, isError
    }
    
    @Published var user: User?
    @Published var chatroom: ChatroomModel?
    private var joined_people: [String] = []
    @Published var firstChatDocument: MessageModel?
    @Published var lastChatDocument: DocumentSnapshot?
    
    private let limit: Int = 40
    
    @Published var messages: [MessageModel]?
    @Published var joinedUsers: [String: UserInfoModel] = [:]
    
    @Published var showAlert: Bool = false
    @Published var activeAlert: ActiveAlert = .isError
    
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
                print("chats 컬렉션 내 문서 없음")
                return
            }
            
            if document.exists {
                self.chatroom = try? document.data(as: ChatroomModel.self)
                
                Task {
                    await self.getUsersData(chatroomModel: try! document.data(as: ChatroomModel.self))
                }
            } else {
                print("ChatroomModel 변환 중 실패")
                
                self.showAlert = true
                self.activeAlert = .isError
            }
        }
    }
    
    func getChatData(docId: String) async {
        let ref = db.collection("chats").document(docId).collection("chat").order(by: "time", descending: true).limit(to: limit)
        
        ref.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("chats 컬렉션 \(docId) 문서의 chat 컬렉션 내 문서가 없음")
                return
            }
            
            if self.messages != nil {
                querySnapshot?.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        if let firstChat = documents.first, let firstChatModel = try? firstChat.data(as: MessageModel.self) {
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
                        return try? document.data(as: MessageModel.self)
                    } else {
                        print("chats 컬렉션 \(docId) 문서의 chat 컬렉션 내 \(document.documentID) 문서가 not exist")
                        self.showAlert = true
                        self.activeAlert = .isError
                        
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
            let querySnapshot = try await ref.getDocuments()
            let documents = querySnapshot.documents 
            
            if !documents.isEmpty{
                let tempMessages = documents.compactMap { document in
                    if document.exists {
                        return try? document.data(as: MessageModel.self)
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
            
            showAlert = true
            activeAlert = .isError
        }
        
        return false
    }
    
    func getUsersData(chatroomModel: ChatroomModel) async {
        for person in Array(Set(chatroomModel.joined_people).subtracting(Set(joined_people))) {
            let ref = db.collection("users").document(person)
            do {
                let document = try await ref.getDocument()
                
                if document.exists {
                    joinedUsers[person] = try? document.data(as: UserInfoModel.self)
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
                showAlert = true
                activeAlert = .isTextError
            }
        } else {
            showAlert = true
            activeAlert = .isError
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
                showAlert = true
                activeAlert = .isImageError
                
                return
            }
            
            let ref = db.collection("chats").document(docId).collection("chat").document("\(dateString)_\(user!.uid)")
            let storageRef = Storage.storage().reference().child("chats/\(docId)/image_\(dateString)_\(user!.uid).jpg")
            
            do {
                let _ = try await storageRef.putDataAsync(imageData, metadata: nil)
                let url: URL = try await storageRef.downloadURL()
                
                try await ref.setData([
                    "image": url.absoluteString,
                    "time": date,
                    "type": "image",
                    "uid": self.user!.uid,
                ])
            } catch {
                print("채팅 이미지 업로드 중 오류: \(error.localizedDescription)")
                self.showAlert = true
                self.activeAlert = .isImageError
            }
        } else {
            showAlert = true
            activeAlert = .isImageError
        }
    }
}
