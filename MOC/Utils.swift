//
//  Utils.swift
//  MOC
//
//  Created by 김태은 on 1/9/25.
//

import Foundation
import FirebaseFirestore

// 키보드 숨기기
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// Timestamp 타입 변환 함수
func formatTimestamp(timestamp: Timestamp) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy. M. d"
    let formattedDate = dateFormatter.string(from: timestamp.dateValue())
    return formattedDate
}

func formatKoreanTimestamp(timestamp: Timestamp) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy년 M월 d일"
    let formattedDate = dateFormatter.string(from: timestamp.dateValue())
    return formattedDate
}
