//
//  ChatModel.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import Foundation
import FirebaseFirestore

struct MessageModel: Codable, Equatable {
    var id: String
    var image: String?
    var text: String?
    var time: Timestamp
    var type: String
    var uid: String
    
    init?(id: String, data: [String: Any]) {
        if let type = data["type"] as? String {
            switch (type) {
            case "text":
                if let text = data["text"] as? String {
                    self.text = text
                } else {
                    print("chatmodel init(type-text) init 실패")
                }
                break
                
            case "image":
                if let image = data["image"] as? String {
                    self.image = image
                } else {
                    print("chatmodel init(type-image) init 실패")
                }
                break
                
            case "welcome":
                print("chatmodel type welcome")
                break
                
            default:
                print("알 수 없는 type")
            }
            
            self.type = type
        } else {
            print("chatmodel init(type) 실패")
            return nil
        }
        
        guard let time = data["time"] as? Timestamp,
              let uid = data["uid"] as? String
        else {
            print("chatmodel init 실패")
            return nil
        }
        
        self.id = id
        self.time = time
        self.uid = uid
    }
}
