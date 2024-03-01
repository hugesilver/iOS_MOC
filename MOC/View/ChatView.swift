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
    
    @State private var cooldown: Bool = false;
    
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
                if let messages = chatViewModel.messages, !messages.isEmpty {
                    let reversedMessages = Array(messages.reversed())
                    
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // Rectangle이 화면 상에 들어왔을 시 실행
                                GeometryReader { geometry in
                                    let rect = geometry.frame(in: .global)
                                    if rect.intersects(UIScreen.main.bounds) {
                                        Rectangle()
                                            .fill(.clear)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .onAppear {
                                                if cooldown && chatViewModel.lastChatDocument != nil {
                                                    cooldown = false
                                                    Task {
                                                        let done: Bool = await chatViewModel.getMoreChatData(docId: docId!)
                                                        if done {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                cooldown = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                                
                                ForEach(reversedMessages.indices, id: \.self) { index in
                                    let message = reversedMessages[index]
                                    let prevMessage = index > 0 ? reversedMessages[index - 1] : nil
                                    let nextMessage = index < reversedMessages.count - 1 ? reversedMessages[index + 1] : nil
                                    MessageBlockView(messages: reversedMessages, message: message, prevMessage: prevMessage, nextMessage: nextMessage, index: index)
                                }
                                
                                Spacer()
                                    .id("bottom")
                            }
                            .rotationEffect(.degrees(180))
                            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
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
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                cooldown = true
                            }
                        }
                        .onChange(of: reversedMessages) {
                            print(reversedMessages.count)
                        }
                    }
                } else {
                    VStack {
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if chatViewModel.messages != nil {
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
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert(isPresented: $chatViewModel.showAlert) {
            switch chatViewModel.activeAlert {
            case .isTextError: return
                Alert(title: Text("오류"), message: Text("메시지 전송 중 오류가 발생하였습니다."), dismissButton: .default(Text("확인")))
                
            case .isImageError: return
                Alert(title: Text("오류"), message: Text("이미지 전송 중 오류가 발생하였습니다."), dismissButton: .default(Text("확인")))
                
            case .isError: return
                Alert(title: Text("오류"), message: Text("기타 오류가 발생하였습니다."), dismissButton: .default(Text("확인")))
            }
        }
        .onAppear {
            if chatViewModel.user != nil {
                Task {
                    await chatViewModel.getChatroomData(docId: docId!)
                    await chatViewModel.getChatData(docId: docId!)
                }
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func MessageBlockView(messages: [MessageModel], message: MessageModel, prevMessage: MessageModel?, nextMessage: MessageModel?, index: Int) -> some View {
        if let user = chatViewModel.user {
            let fromMe: Bool = message.uid == user.uid
            
            let isPrevSamePerson: Bool = prevMessage != nil && prevMessage!.uid == message.uid
            let isPrevSameDate: Bool = prevMessage != nil && getDateTime(timestamp: prevMessage!.time) == getDateTime(timestamp: message.time)
            let isPrevSameDay: Bool = prevMessage != nil && getDay(timestamp: prevMessage!.time) == getDay(timestamp: message.time)
            
            // let isNextSamePerson: Bool = nextMessage != nil && nextMessage!.uid == message.uid
            let isNextSameDate: Bool = nextMessage != nil && getDateTime(timestamp: nextMessage!.time) == getDateTime(timestamp: message.time)
            
            return AnyView(
                VStack(spacing: 0) {
                    if prevMessage == nil || !isPrevSameDay {
                        DateBlockView(timestamp: message.time)
                            .padding(.bottom, 20)
                    }
                    
                    if message.type == "welcome" {
                        WhichBlockView(message: message, fromMe: fromMe)
                            .padding(.bottom, 20)
                    }
                    else {
                        HStack(alignment: .bottom, spacing: 0) {
                            if fromMe {
                                Spacer()
                                
                                TimeBlockView(timestamp: message.time, fromMe: fromMe, isLastMinute: nextMessage == nil || !isNextSameDate)
                                    .padding(.trailing, 7)
                                
                                WhichBlockView(message: message, fromMe: fromMe)
                            }
                            
                            if !fromMe {
                                if (prevMessage!.type == "welcome" && prevMessage!.uid == message.uid) || (!isPrevSamePerson || !isPrevSameDate) {
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
                                        if let nickname = chatViewModel.joinedUsers[message.uid]?.nickname {
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
                                        
                                        WhichBlockView(message: message, fromMe: fromMe)
                                    }
                                    .padding(.trailing, 7)
                                } else {
                                    WhichBlockView(message: message, fromMe: fromMe)
                                        .padding(.leading, 53)
                                        .padding(.trailing, 7)
                                }
                                
                                TimeBlockView(timestamp: message.time, fromMe: fromMe, isLastMinute: nextMessage == nil || !isNextSameDate)
                                
                                Spacer()
                            }
                        }
                    }
                }
                    .frame(maxWidth: .infinity)
                    .padding(.top, prevMessage == nil || prevMessage!.type == "welcome" ? 0 : !isPrevSameDay ? 20 : isPrevSamePerson && isPrevSameDate ? 5 : fromMe ? 10 : 20)
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
    
    func WhichBlockView(message: MessageModel, fromMe: Bool) -> some View {
        switch (message.type) {
        case "text":
            return AnyView(TextBlockView(text: message.text!, fromMe: fromMe))
        case "image":
            return AnyView(ImageBlockView(image: message.image!))
        case "welcome":
            return AnyView(WelcomeView(nickname: chatViewModel.joinedUsers[message.uid]?.nickname ?? "Unknown"))
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
