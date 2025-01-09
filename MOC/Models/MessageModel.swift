//
//  ChatModel.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct MessageModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let image: String?
    let text: String?
    let time: Timestamp
    let type: String
    let uid: String
}
