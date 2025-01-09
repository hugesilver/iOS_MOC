//
//  ChatroomModel.swift
//  MOC
//
//  Created by 김태은 on 2/16/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatroomModel: Identifiable, Codable {
    @DocumentID var id: String?
    let create_date: Timestamp
    let creator: String
    let joined_people: [String]
    let thumbnail: String
    let title: String
}
