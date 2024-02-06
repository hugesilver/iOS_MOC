//
//  UserInfoModel.swift
//  MOC
//
//  Created by 김태은 on 1/29/24.
//

import Foundation
import FirebaseFirestore

struct UserInfoModel: Codable {
    var created_chatrooms: Array<String>
    var joined_chatrooms: Array<String>
    var nickname: String
    var profile_image: String
    var signup_date: Date
    var uid: String
    
    init?(data: [String: Any]) {
        guard let created_chatrooms = data["created_chatrooms"] as? Array<String>,
              let joined_chatrooms = data["joined_chatrooms"] as? Array<String>,
              let nickname = data["nickname"] as? String,
              let profile_image = data["profile_image"] as? String,
              let signup_date = data["signup_date"] as? Date,
              let uid = data["uid"] as? String
        else {
            return nil
        }
        
        self.created_chatrooms = created_chatrooms
        self.joined_chatrooms = joined_chatrooms
        self.nickname = nickname
        self.profile_image = profile_image
        self.signup_date = signup_date
        self.uid = uid
    }
}