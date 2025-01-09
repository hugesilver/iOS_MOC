//
//  MessageBlocks.swift
//  MOC
//
//  Created by 김태은 on 1/9/25.
//

import SwiftUI
import FirebaseFirestore

// 날짜 메시지 블록
struct DateMessageBlock: View {
    let timestamp: Timestamp
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("MOCGray"))
                .frame(width: 200)
            
            Text(formattedDate())
                .font(.custom("Pretendard", size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("MOCWhite"))
                .padding(.vertical, 6)
        }
    }
    
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return dateFormatter.string(from: timestamp.dateValue())
    }
}

// 시간 메시지 블록
struct TimeMessageBlock: View {
    let timestamp: Timestamp
    let fromMe: Bool
    let isLastMinute: Bool
    
    var body: some View {
        ZStack(alignment: fromMe ? .trailing : .leading) {
            EmptyView()
                .frame(width: 50)
            
            Text(formattedDate())
                .font(Font.custom("Pretendard", size: 10))
                .foregroundColor(isLastMinute ? Color("MOCGray") : Color("MOCBackground"))
        }
    }
    
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "a h:mm"
        return dateFormatter.string(from: timestamp.dateValue())
    }
}

// 텍스트 메시지 블록
struct TextMessageBlock: View {
    let text: String
    let fromMe: Bool
    
    var body: some View {
        Text(text)
            .font(.custom("Pretendard", size: 18))
            .multilineTextAlignment(.leading)
            .padding(10)
            .foregroundColor(fromMe ? Color("MOCWhite") : Color("MOCTextColor"))
            .background(fromMe ? Color("MOCBlue") : Color("MOCGray"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxHeight: .infinity)
    }
}

// 이미지 메시지 블록
struct ImageMessageBlock: View {
    let image: String
    
    var body: some View {
        AsyncImage(url: URL(string:image)) {
            image in image.resizable()
        } placeholder: {
            Color("MOCDarkGray")
        }
        .aspectRatio(contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
    }
}

struct WelcomeMessageBlock: View {
    let nickname: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("MOCDarkGray"))
                .frame(maxWidth: .infinity)
            
            Text("\(nickname)님이 입장하셨습니다.")
                .font(.custom("Pretendard", size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("MOCWhite"))
                .padding(.vertical, 6)
        }
    }
}

// 메시지 구별 블록
struct MessageBlock: View {
    let message: MessageModel
    let fromMe: Bool
    
    var body: some View {
        switch (message.type) {
        case "text":
            TextMessageBlock(text: message.text!, fromMe: fromMe)
        case "image":
            ImageMessageBlock(image: message.image!)
        default:
            EmptyView()
        }
    }
}

// 챗 블록
struct ChatBlock: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    let messages: [MessageModel]
    let message: MessageModel
    let prevMessage: MessageModel?
    let nextMessage: MessageModel?
    let index: Int
    
    var body: some View {
        if let user = chatViewModel.user {
            let fromMe: Bool = message.uid == user.uid
            
            let isPrevSamePerson: Bool = prevMessage != nil && prevMessage!.uid == message.uid
            let isPrevSameDate: Bool = prevMessage != nil && getDateTime(timestamp: prevMessage!.time) == getDateTime(timestamp: message.time)
            let isPrevSameDay: Bool = prevMessage != nil && getDay(timestamp: prevMessage!.time) == getDay(timestamp: message.time)
            
            // let isNextSamePerson: Bool = nextMessage != nil && nextMessage!.uid == message.uid
            let isNextSameDate: Bool = nextMessage != nil && getDateTime(timestamp: nextMessage!.time) == getDateTime(timestamp: message.time)
            
            VStack(spacing: 0) {
                if prevMessage == nil || !isPrevSameDay {
                    DateMessageBlock(timestamp: message.time)
                        .padding(.bottom, 20)
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    if fromMe {
                        Spacer()
                        
                        TimeMessageBlock(timestamp: message.time, fromMe: fromMe, isLastMinute: nextMessage == nil || message.uid != nextMessage!.uid || !isNextSameDate)
                            .padding(.trailing, 7)
                        
                        MessageBlock(message: message, fromMe: fromMe)
                    } else {
                        if (prevMessage?.type == "welcome" && prevMessage!.uid == message.uid) || (!isPrevSamePerson || !isPrevSameDate) {
                            if let profile = chatViewModel.joinedUsers[message.uid], profile.profile_image != "" {
                                AsyncImage(url: URL(string: profile.profile_image)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color("MOCDarkGray")
                                }
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 43, height: 43)
                                .padding(.trailing, 10)
                            } else {
                                Circle()
                                    .frame(width: 43, height: 43)
                                    .foregroundColor(Color("MOCDarkGray"))
                                    .padding(.trailing, 10)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(chatViewModel.joinedUsers[message.uid]?.nickname ?? "Unknown")
                                    .font(Font.custom("Pretendard", size: 14))
                                    .foregroundColor(Color("MOCDarkGray"))
                                    .padding(.bottom, 2)
                                
                                MessageBlock(message: message, fromMe: fromMe)
                            }
                            .padding(.trailing, 7)
                        } else {
                            MessageBlock(message: message, fromMe: fromMe)
                                .padding(.leading, 53)
                                .padding(.trailing, 7)
                        }
                        
                        TimeMessageBlock(timestamp: message.time, fromMe: fromMe, isLastMinute: nextMessage == nil || message.uid != nextMessage!.uid || !isNextSameDate)
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, prevMessage == nil || prevMessage!.type == "welcome" ? 0 : !isPrevSameDay ? 20 : isPrevSamePerson && isPrevSameDate ? 5 : fromMe ? 10 : 20)
        } else {
            EmptyView()
        }
    }
    
    func getDateTime(timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhh:mm"
        let minutes = dateFormatter.string(from: timestamp.dateValue())
        
        return minutes
    }
    
    func getDay(timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: timestamp.dateValue())
        
        return day
    }
}
