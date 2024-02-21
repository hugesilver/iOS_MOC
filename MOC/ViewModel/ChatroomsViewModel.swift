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
    
    private let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            self.user = user
        }
    }
    
    func getChatrooms() async {
        let ref = db.collection("chatrooms").order(by: "create_date", descending: true)
        
        do {
            let querySnapshot = try await ref.getDocuments()
            print("chatrooms 불러오기 성공")
            
            chatrooms = querySnapshot.documents.compactMap { document in
                if document.exists {
                    return ChatroomModel(id: document.documentID, data: document.data())
                } else {
                    print("chatrooms 내 문서 없음")
                    return nil
                }
            }
        } catch {
            print("채팅방 목록을 불러오는 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    func joinChatroom(docId: String) async {
        let chatroomsRef = db.collection("chatrooms").document(docId)
        let chatsRef = db.collection("chats").document(docId)
        
        if user != nil {
            do {
                try await chatroomsRef.updateData(["joined_people" : FieldValue.arrayUnion([user!.uid])])
            } catch {
                print("chatroomsRef 업데이트 중 오류 발생")
            }
            
            do {
                try await chatsRef.updateData(["joined_people" : FieldValue.arrayUnion([user!.uid])])
            } catch {
                print("chatsRef 업데이트 중 오류 발생")
            }
        }
        
    }
}
