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
    @Environment(\.dismiss) var dismiss
    
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
                            dismiss()
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
                                    
                                    if message.type == "welcome" {
                                        WelcomeMessageBlock(nickname: chatViewModel.joinedUsers[message.uid]?.nickname ?? "Unknown")
                                            .padding(.top, index != 0 ? 20 : 0)
                                            .padding(.bottom, 20)
                                    } else {
                                        ChatBlock(
                                            chatViewModel: chatViewModel,
                                            messages: reversedMessages,
                                            message: message,
                                            prevMessage: prevMessage,
                                            nextMessage: nextMessage,
                                            index: index
                                        )
                                    }
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
                    }
                } else {
                    EmptyView()
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
}

//#Preview {
//    ChatView()
//}
