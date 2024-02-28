//
//  ChatView.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import SwiftUI
import FirebaseFirestore
import PhotosUI

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var docId: String?
    @State private var text: String = ""
    @State private var photosPickerItem: PhotosPickerItem?
    
    @StateObject var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 75)
                        .overlay(
                            Image("IconArrowBack")
                                .resizable()
                                .frame(width: 12, height: 20)
                                .padding(.leading, 20)
                                .tint(Color("MOCDarkGray"))
                            , alignment: .leading
                        )
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                    
                    Spacer()
                        .overlay(
                            Text(chatViewModel.chatroom?.title ?? "")
                                .font(
                                    .custom("Pretendard", size: 22)
                                    .weight(.medium)
                                )
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color("MOCTextColor"))
                        )
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 75)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 75)
                .overlay(
                    Rectangle()
                        .foregroundColor(Color("MOCGray"))
                        .frame(height: 1)
                    , alignment: .bottom
                )
                
                // 채팅 영역
                if let chats = chatViewModel.chats, !chats.isEmpty {
                    let reversedChats = Array(chats.reversed())
                    
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if chatViewModel.lastChatDocument != nil {
                                    Text("눌러서 더 불러오기")
                                        .font(
                                            .custom("Pretendard", size: 14)
                                            .weight(.medium)
                                        )
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color("MOCBlue"))
                                        .padding(.vertical, 10)
                                        .onTapGesture {
                                            if chatViewModel.lastChatDocument != nil {
                                                Task {
                                                    await chatViewModel.getMoreChatData(docId: docId!)
                                                }
                                            }
                                        }
                                } else {
                                    Rectangle()
                                        .fill(Color("MOCBackground"))
                                        .frame(height: 20)
                                        .frame(maxWidth: .infinity)
                                }
                                
                                ForEach(reversedChats.indices, id: \.self) { index in
                                    let chat = reversedChats[index]
                                    let prevChat = index > 0 ? reversedChats[index - 1] : nil
                                    let nextChat = index < reversedChats.count - 1 ? reversedChats[index + 1] : nil
                                    ChatBlockView(chats: reversedChats, chat: chat, prevChat: prevChat, nextChat: nextChat, index: index)
                                }
                                
                                Spacer()
                                    .id("bottom")
                            }
                            .rotationEffect(.degrees(180))
                            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .onChange(of: chatViewModel.firstChatDocument) {
                            if let firstChat = chatViewModel.firstChatDocument, let user = chatViewModel.user {
                                if firstChat.uid == user.uid {
                                    scrollView.scrollTo("bottom")
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if chatViewModel.chats != nil {
                    // 입력창
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("MOCWhite"))
                        .stroke(Color("MOCDarkGray"), lineWidth: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 33)
                        .overlay(
                            HStack(spacing: 7) {
                                TextField("", text: $text)
                                    .background(Color("MOCBackground")).font(
                                        .custom("Pretendard", size: 15)
                                    )
                                    .foregroundColor(Color("MOCTextColor"))
                                    .multilineTextAlignment(.leading)
                                    .onChange(of: text) { _, _ in
                                        text = String(text.prefix(300))
                                    }
                                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("MOCYellow"))
                                        .frame(width: 31, height: 23)
                                        .overlay(
                                            Image("IconCamera")
                                                .resizable()
                                                .frame(width: 14.5, height: 11.6)
                                        )
                                }
                                .onChange(of: photosPickerItem) { image, _ in
                                    Task {
                                        guard let data = try? await image?.loadTransferable(type: Data.self) else { return }
                                        await chatViewModel.sendImage(docId: docId!, image: UIImage(data: data)!)
                                    }
                                    
                                    photosPickerItem = nil
                                }
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(text.isEmpty ? Color("MOCGray") : Color("MOCBlue"))
                                    .frame(width: 31, height: 23)
                                    .overlay(
                                        Image("IconPlane")
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                    )
                                    .onTapGesture {
                                        if !text.isEmpty {
                                            let tempText = text
                                            text = ""
                                            
                                            Task {
                                                await chatViewModel.sendText(docId: docId!, text: tempText)
                                            }
                                        }
                                    }
                            }
                                .padding(.horizontal, 10)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                
            }
        }
        .background(Color("MOCBackground"))
        .onAppear {
            if chatViewModel.user != nil {
                Task {
                    await chatViewModel.getChatroomData(docId: docId!)
                    await chatViewModel.getChatData(docId: docId!)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func ChatBlockView(chats: [MessageModel], chat: MessageModel, prevChat: MessageModel?, nextChat: MessageModel?, index: Int) -> some View {
        if let user = chatViewModel.user {
            let fromMe: Bool = chat.uid == user.uid
            
            let isPrevSamePerson: Bool = prevChat != nil && prevChat!.uid == chat.uid
            let isPrevSameDate: Bool = prevChat != nil && getDateTime(timestamp: prevChat!.time) == getDateTime(timestamp: chat.time)
            let isPrevSameDay: Bool = prevChat != nil && getDay(timestamp: prevChat!.time) == getDay(timestamp: chat.time)
            
            // let isNextSamePerson: Bool = nextChat != nil && nextChat!.uid == chat.uid
            let isNextSameDate: Bool = nextChat != nil && getDateTime(timestamp: nextChat!.time) == getDateTime(timestamp: chat.time)
            
            return AnyView(
                VStack(spacing: 0) {
                    if prevChat == nil || !isPrevSameDay {
                        DateBlockView(timestamp: chat.time)
                            .padding(.bottom, 20)
                    }
                    
                    if chat.type == "welcome" {
                        WhichBlockView(chat: chat, fromMe: fromMe)
                            .padding(.bottom, 20)
                    }
                    else {
                        HStack(alignment: .bottom, spacing: 0) {
                            if fromMe {
                                Spacer()
                                
                                TimeBlockView(timestamp: chat.time, fromMe: fromMe, isLastMinute: nextChat == nil || !isNextSameDate)
                                    .padding(.trailing, 7)
                                
                                WhichBlockView(chat: chat, fromMe: fromMe)
                            }
                            
                            if !fromMe {
                                if (prevChat!.type == "welcome" && prevChat!.uid == chat.uid) || (!isPrevSamePerson || !isPrevSameDate) {
                                    if let profile = chatViewModel.joinedUsers[chat.uid], profile.profile_image != "" {
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
                                        if let nickname = chatViewModel.joinedUsers[chat.uid]?.nickname {
                                            Text(nickname)
                                                .font(Font.custom("Pretendard", size: 14))
                                                .foregroundColor(Color("MOCDarkGray"))
                                                .padding(.bottom, 2)
                                        } else {
                                            Text("Unknown")
                                                .font(Font.custom("Pretendard", size: 14))
                                                .foregroundColor(Color("MOCDarkGray"))
                                                .padding(.bottom, 2)
                                        }
                                        
                                        WhichBlockView(chat: chat, fromMe: fromMe)
                                    }
                                    .padding(.trailing, 7)
                                } else {
                                    WhichBlockView(chat: chat, fromMe: fromMe)
                                        .padding(.leading, 53)
                                        .padding(.trailing, 7)
                                }
                                
                                TimeBlockView(timestamp: chat.time, fromMe: fromMe, isLastMinute: nextChat == nil || !isNextSameDate)
                                
                                Spacer()
                            }
                        }
                    }
                }
                    .frame(maxWidth: .infinity)
                    .padding(.top, prevChat == nil || prevChat!.type == "welcome" ? 0 : !isPrevSameDay ? 20 : isPrevSamePerson && isPrevSameDate ? 5 : fromMe ? 10 : 20)
            )
        }
        
        return AnyView(EmptyView())
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
    
    func DateBlockView(timestamp: Timestamp) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 d일 EEEE"
        let formattedDate = dateFormatter.string(from: timestamp.dateValue())
        
        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("MOCGray"))
                .frame(width: 200)
            
            Text(formattedDate)
                .font(.custom("Pretendard", size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("MOCWhite"))
                .padding(.vertical, 6)
        }
    }
    
    func TimeBlockView(timestamp: Timestamp, fromMe: Bool, isLastMinute: Bool) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "a h:mm"
        let formattedDate = dateFormatter.string(from: timestamp.dateValue())
        
        return ZStack(alignment: fromMe ? .trailing : .leading) {
            EmptyView()
                .frame(width: 50)
            
            Text(formattedDate)
                .font(Font.custom("Pretendard", size: 10))
                .foregroundColor(isLastMinute ? Color("MOCGray") : Color("MOCBackground"))
        }
    }
    
    func WhichBlockView(chat: MessageModel, fromMe: Bool) -> some View {
        switch (chat.type) {
        case "text":
            return AnyView(TextBlockView(text: chat.text!, fromMe: fromMe))
        case "image":
            return AnyView(ImageBlockView(image: chat.image!))
        case "welcome":
            return AnyView(WelcomeView(nickname: chatViewModel.joinedUsers[chat.uid]?.nickname ?? "Unknown"))
        default:
            return AnyView(EmptyView())
        }
    }
    
    func TextBlockView(text: String, fromMe: Bool) -> some View {
        return Text(text)
            .font(.custom("Pretendard", size: 18))
            .multilineTextAlignment(.leading)
            .padding(10)
            .foregroundColor(fromMe ? Color("MOCWhite") : Color("MOCTextColor"))
            .background(fromMe ? Color("MOCBlue") : Color("MOCGray"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxHeight: .infinity)
    }
    
    func ImageBlockView(image: String) -> some View {
        return AsyncImage(url: URL(string:image)) {
            image in image.resizable()
        } placeholder: {
            Color("MOCDarkGray")
        }
        .aspectRatio(contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
    }
    
    func WelcomeView(nickname: String) -> some View {
        return ZStack {
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

//#Preview {
//    ChatView()
//}
