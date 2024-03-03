//
//  ChatListView.swift
//  MOC
//
//  Created by 김태은 on 2/7/24.
//

import SwiftUI
import FirebaseFirestore

struct ChatListView: View {
    @StateObject var userInfoViewModel = UserInfoViewModel()
    @StateObject var chatroomsViewModel = ChatroomsViewModel()
    
    @State var showAlert: Bool = false
    @State var chatroomDocId: String?
    
    @State var isChat: Bool = false
    @State var isCreate: Bool = false
    @State var isSetting: Bool = false
    
    private let maxOffset: CGFloat = UIScreen.main.bounds.height * 0.18
    private let closeOffset: CGFloat = UIScreen.main.bounds.height * 0.3
    private let minOffset: CGFloat = UIScreen.main.bounds.height
    
    @State private var showMypage = false
    @State private var mypageOffset: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    
    @GestureState private var gestureTranslation: CGFloat = 0
    
    @State var imageUpdated: Bool = false
    @State var selectImage: UIImage?
    
    @State var nav = []
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // ChatList
                VStack {
                    // 헤더
                    HStack(alignment: .center) {
                        Text("채팅")
                            .font(
                                .custom("Pretendard", size: 36)
                                .weight(.bold)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                        
                        Spacer()
                        
                        // 마이페이지
                        if let localProfileImage = selectImage {
                            Image(uiImage: localProfileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                )
                                .onTapGesture {
                                    showMypage = true
                                    mypageOffset = maxOffset
                                }
                        } else if let profile = userInfoViewModel.userInfo?.profile_image, profile != "" {
                            AsyncImage(url: URL(string: profile)) { image in
                                image.resizable()
                            } placeholder: {
                                Color("MOCDarkGray")
                            }
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(Color("MOCDarkGray"), lineWidth: 1)
                            )
                            .onTapGesture {
                                showMypage = true
                                mypageOffset = maxOffset
                            }
                        } else {
                            Circle()
                                .frame(width: 42, height: 42)
                                .foregroundColor(Color("MOCDarkGray"))
                                .overlay(
                                    Circle()
                                        .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                )
                                .onTapGesture {
                                    showMypage = true
                                    mypageOffset = maxOffset
                                }
                        }
                    }
                    
                    // 채팅방 목록
                    if let chatrooms = chatroomsViewModel.chatrooms, chatrooms.count > 0 {
                        ScrollView {
                            VStack(spacing: 0) {
                                LazyVStack(spacing: 20) {
                                    ForEach(chatrooms, id: \.id) { chatroom in
                                        chatroomBlock(data: chatroom)
                                            .onTapGesture {
                                                chatroomDocId = chatroom.id
                                                
                                                if chatroomsViewModel.user != nil {
                                                    if !chatroom.joined_people.contains(chatroomsViewModel.user!.uid) {
                                                        showAlert = true
                                                    } else {
                                                        isChat = true
                                                    }
                                                }
                                            }
                                    }
                                }
                                Rectangle()
                                    .fill(Color("MOCBackground"))
                                    .frame(height: 20)
                                    .onAppear {
                                        if chatroomsViewModel.lastChatroomDocument != nil {
                                            Task {
                                                await chatroomsViewModel.getMoreChatRooms()
                                            }
                                        }
                                    }
                            }
                            .padding(.top, 50)
                        }
                        .refreshable {
                            if chatroomsViewModel.user != nil {
                                Task {
                                    await chatroomsViewModel.getChatrooms()
                                }
                            }
                        }
                        
                    } else {
                        VStack(alignment: .center) {
                            Text("아직 채팅방이 없어요.")
                                .font(Font.custom("Pretendard", size: 16))
                                .foregroundColor(Color("MOCDarkGray"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .background(Color("MOCBackground"))
                
                if showMypage {
                    Color.black.opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showMypage = false
                        }
                }
                
                // 마이페이지
                MypageView(userInfo: $userInfoViewModel.userInfo, selectImage: $selectImage, imageUpdated: $imageUpdated, isChat: $isChat, isCreate: $isCreate, isSetting: $isSetting, chatroomDocId: $chatroomDocId)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 32,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 32
                        )
                    )
                    .offset(y: showMypage ? max(mypageOffset, maxOffset) : UIScreen.main.bounds.height)
                    .animation(.spring(), value: showMypage)
                    .gesture(
                        DragGesture()
                            .updating($gestureTranslation) { value, state, _ in
                                state = value.translation.height
                            }
                            .onChanged { gesture in
                                mypageOffset = gesture.translation.height
                            }
                            .onEnded { gesture in
                                if mypageOffset > closeOffset {
                                    showMypage = false
                                } else {
                                    mypageOffset = maxOffset
                                }
                            }
                    )
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.82)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            UINavigationBar.setAnimationsEnabled(true)
            if userInfoViewModel.user != nil {
                Task {
                    await userInfoViewModel.listenUserDocument(uid: userInfoViewModel.user!.uid)
                }
            }
            
            if chatroomsViewModel.user != nil {
                Task {
                    await chatroomsViewModel.getChatrooms()
                }
            }
        }
        .onChange(of: imageUpdated) {
            if imageUpdated {
                imageUpdated = false
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("확인"),
                message: Text("해당 채팅방에 입장하시겠습니까?"),
                primaryButton: .default(Text("입장"), action: {
                    Task {
                        await chatroomsViewModel.joinChatroom(docId: chatroomDocId!)
                        await chatroomsViewModel.getChatrooms()
                    }
                    
                    isChat = true
                }),
                secondaryButton: .default(Text("취소"))
            )
        }
        .navigationDestination(isPresented: $isChat, destination: {
            ChatView(docId: $chatroomDocId)
        })
        .navigationDestination(isPresented: $isCreate, destination: {
            CreateChatroomView()
        })
        .navigationDestination(isPresented: $isSetting, destination: {
            SettingAccountView()
        })
    }
    
    func chatroomBlock(data: ChatroomModel) -> some View {
        return RoundedRectangle(cornerRadius: 16)
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
    
    // Timestamp 타입 변환 함수
    func formatTimestamp(timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy. M. d"
        let formattedDate = dateFormatter.string(from: timestamp.dateValue())
        return formattedDate
    }
}

//#Preview {
//    ChatListView()
//}
