//
//  UserInfoModel.swift
//  MOC
//
//  Created by 김태은 on 1/29/24.
//

import Foundation
import FirebaseFirestore

struct UserInfoModel: Codable {
    var created_chatrooms: [String]
    var joined_chatrooms: [String]
    var nickname: String
    var profile_image: String
    var signup_date: Timestamp
    var uid: String
}
