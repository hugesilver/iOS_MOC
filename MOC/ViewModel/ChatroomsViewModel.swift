//
//  ChatroomsViewModel.swift
//  MOC
//
//  Created by 김태은 on 2/16/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ChatroomsViewModel: ObservableObject {
    @Published var user: User?
    @Published var chatrooms: [ChatroomModel]?
    var lastChatroomDocument: DocumentSnapshot?
    
    @Published var created_chatrooms: [ChatroomModel]?
    @Published var joined_chatrooms: [ChatroomModel]?
    
    private let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            self.user = user
        }
    }
    
    func getChatrooms() async {
        let limit: Int = 10
        let ref = db.collection("chatrooms").order(by: "create_date", descending: true).limit(to: limit)
        
        do {
            let querySnapshot = try await ref.getDocuments()
            let documents = querySnapshot.documents
            
            if !documents.isEmpty{
                chatrooms = documents.compactMap { document in
                    if document.exists {
                        return ChatroomModel(id: document.documentID, data: document.data())
                    } else {
                        print("chatrooms 내 문서 없음")
                        return nil
                    }
                }
                
                if querySnapshot.documents.count >= limit {
                    lastChatroomDocument = querySnapshot.documents.last
                } else {
                    lastChatroomDocument = nil
                }
            }
        } catch {
            print("채팅방 목록을 불러오는 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    func getMoreChatRooms() async {
        let limit: Int = 10
        var ref = db.collection("chatrooms").order(by: "create_date", descending: true).limit(to: limit)
        
        if let lastChatroomDocument {
            ref = ref.start(afterDocument: lastChatroomDocument)
        }
        
        do {
            let querySnapshot = try await ref.getDocuments()
            let documents = querySnapshot.documents
            
            let models = documents.compactMap { document in
                if document.exists {
                    return ChatroomModel(id: document.documentID, data: document.data())
                } else {
                    print("chatrooms 내 문서 없음")
                    return nil
                }
            }
            
            chatrooms = chatrooms! + models
            
            if querySnapshot.documents.count >= limit {
                lastChatroomDocument = querySnapshot.documents.last
            } else {
                lastChatroomDocument = nil
            }
        } catch {
            print("채팅방 목록을 불러오는 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    func joinChatroom(docId: String) async {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSS"
        let dateString = formatter.string(from: date)
        
        let chatroomsRef = db.collection("chatrooms").document(docId)
        let chatsRef = db.collection("chats").document(docId)
        
        if user != nil {
            let usersRef = db.collection("users").document(user!.uid)
            
            do {
                try await chatroomsRef.updateData(["joined_people" : FieldValue.arrayUnion([user!.uid])])
            } catch {
                print("chatroomsRef 업데이트 중 오류 발생: \(error.localizedDescription)")
            }
            
            do {
                try await chatsRef.updateData(["joined_people" : FieldValue.arrayUnion([user!.uid])])
            } catch {
                print("chatsRef 업데이트 중 오류 발생: \(error.localizedDescription)")
            }
            
            do {
                try await usersRef.updateData(["joined_chatrooms" : FieldValue.arrayUnion([docId])])
            } catch {
                print("users joined_chatrooms 업데이트 중 오류 발생: \(error.localizedDescription)")
            }
            
            do {
                try await chatsRef.collection("chat").document("\(dateString)_\(user!.uid)").setData([
                    "time": date,
                    "type": "welcome",
                    "uid": user!.uid,
                ])
            } catch {
                print("chatsRef welcome 메시지 생성 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
    
    func getCreatedChatrooms() async {
        if user != nil {
            let query = db.collection("chatrooms").order(by: "create_date", descending: true).whereField("creator", isEqualTo: user!.uid)
            
            do {
                let querySnapshot = try await query.getDocuments()
                let documents = querySnapshot.documents
                
                if !documents.isEmpty {
                    created_chatrooms = documents.compactMap { document in
                        if document.exists {
                            return ChatroomModel(id: document.documentID, data: document.data())
                        } else {
                            print("getCreatedChatrooms 함수 실행 중 chatrooms 내 문서 없음")
                            return nil
                        }
                    }
                }
            } catch {
                print("created_chatrooms 처리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
    
    func getJoinedChatrooms() async {
        if user != nil {
            let query = db.collection("chatrooms").order(by: "create_date", descending: true).whereField("joined_people", arrayContains: user!.uid)
            
            do {
                let querySnapshot = try await query.getDocuments()
                let documents = querySnapshot.documents
                
                if !documents.isEmpty {
                    joined_chatrooms = documents.compactMap { document in
                        if document.exists {
                            return ChatroomModel(id: document.documentID, data: document.data())
                        } else {
                            print("getJoinedChatrooms 함수 실행 중 chatrooms 내 문서 없음")
                            return nil
                        }
                    }
                }
            } catch {
                print("joined_chatrooms 처리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
    
    func createChatroom(title: String, thumbnail: UIImage?) async -> Bool {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSS"
        let dateString = formatter.string(from: date)
        
        let docId = "\(dateString)_\(user!.uid)"
        
        if user != nil {
            if thumbnail != nil {
                guard let imageData = thumbnail!.jpegData(compressionQuality: 0.5) else {
                    print("이미지 jpeg로 변환 중 오류")
                    
                    return false
                }
                
                let storageRef = Storage.storage().reference().child("chatrooms/\(docId)/thumbnail_\(docId).jpg")
                
                storageRef.putData(imageData, metadata: nil) { _, _ in
                    Task {
                        do {
                            let url: URL = try await storageRef.downloadURL()
                            await self.createChatroomDocuments(docId: docId, date: date, title: title, thumbnailLink: url.absoluteString)
                        } catch {
                            print("이미지 업로드 중 오류: \(error.localizedDescription)")
                            return false
                        }
                        return true
                    }
                }
            } else {
                await createChatroomDocuments(docId: docId, date: date, title: title, thumbnailLink: nil)
            }
            
            print("채팅방 생성 완료")
            return true
        }
        
        return false
    }
    
    func createChatroomDocuments(docId: String, date: Date, title: String, thumbnailLink: String?) async {
        let usersRef = db.collection("users").document(user!.uid)
        let chatroomsref = db.collection("chatrooms").document(docId)
        let chatsref = db.collection("chats").document(docId)
        
        do {
            try await chatroomsref.setData([
                "create_date": date,
                "creator": user!.uid,
                "joined_people": [user!.uid],
                "thumbnail": thumbnailLink ?? "",
                "title": title,
            ])
        } catch {
            print("채팅방 생성 중(chatrooms) 실패: \(error.localizedDescription)")
        }
        
        do {
            try await chatsref.setData([
                "create_date": date,
                "creator": user!.uid,
                "joined_people": [user!.uid],
                "thumbnail": thumbnailLink ?? "",
                "title": title,
            ])
            
            try await chatsref.collection("chat").document(docId).setData([
                "time": date,
                "type": "welcome",
                "uid": user!.uid,
            ])
        } catch {
            print("채팅방 생성 중(chats) 실패: \(error.localizedDescription)")
        }
        
        do {
            try await usersRef.updateData(["created_chatrooms" : FieldValue.arrayUnion([docId])])
            try await usersRef.updateData(["joined_chatrooms" : FieldValue.arrayUnion([docId])])
        } catch {
            print("채팅방 생성 중(users) 실패: \(error.localizedDescription)")
        }
    }
}
