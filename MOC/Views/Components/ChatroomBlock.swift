//
//  ChatroomBlock.swift
//  MOC
//
//  Created by 김태은 on 1/9/25.
//

import SwiftUI

struct ChatroomBlock: View {
    let data: ChatroomModel
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("MOCBackground"))
            .stroke(Color("MOCLightGray"), lineWidth: 1)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .overlay(
                HStack {
                    // 채팅방 정보
                    VStack(alignment: .leading, spacing: 0) {
                        Text(data.title)
                            .font(
                                .custom("Pretendard", size: 16)
                                .weight(.medium)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                            .padding(.bottom, 2)
                        
                        HStack(spacing: 2) {
                            Text("참여자")
                                .font(Font.custom("Pretendard", size: 12))
                                .foregroundColor(Color("MOCPink"))
                            
                            Text("\(data.joined_people.count)명")
                                .font(Font.custom("Pretendard", size: 12))
                                .foregroundColor(Color("MOCTextColor"))
                        }
                        
                        Spacer()
                        
                        Text("\(formatTimestamp(timestamp: data.create_date)) 개설")
                            .font(Font.custom("Pretendard", size: 10))
                            .foregroundColor(Color("MOCDarkGray"))
                    }
                    
                    Spacer()
                    
                    // 썸네일
                    if data.thumbnail != "" {
                        AsyncImage(url: URL(string: data.thumbnail)) { image in
                            image
                                .resizable()
                                .frame(width: 80, height: 80)
                        } placeholder: {
                            Color("MOCDarkGray")
                        }
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .frame(width: 80, height: 80)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("MOCDarkGray"))
                            .frame(width: 80, height: 80)
                    }
                }
                    .padding(20)
            )
    }
}
