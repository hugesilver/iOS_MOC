//
//  ChatroomModel.swift
//  MOC
//
//  Created by 김태은 on 2/16/24.
//

import Foundation
import FirebaseFirestore

struct ChatroomModel: Codable {
    var id: String
    var create_date: Timestamp
    var creator: String
    var joined_people: [String]
    var thumbnail: String
    var title: String
    
    init?(id: String, data: [String: Any]) {
        guard let create_date = data["create_date"] as? Timestamp,
              let creator = data["creator"] as? String,
              let joined_people = data["joined_people"] as? [String],
              let thumbnail = data["thumbnail"] as? String,
              let title = data["title"] as? String
        else {
            print("chatroommodel init 실패")
            return nil
        }
        
        self.id = id
        self.create_date = create_date
        self.creator = creator
        self.joined_people = joined_people
        self.thumbnail = thumbnail
        self.title = title
    }
}
