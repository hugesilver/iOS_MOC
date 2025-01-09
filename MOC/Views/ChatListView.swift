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
    
    @State private var showMypage = false
    @State private var mypageOffset: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    
    @GestureState private var gestureTranslation: CGFloat = 0
    
    @State var imageUpdated: Bool = false
    @State var selectImage: UIImage?
    
    @State var nav = []
    
    var body: some View {
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
                    Group {
                        if let localProfileImage = selectImage {
                            Image(uiImage: localProfileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let profile = userInfoViewModel.userInfo?.profile_image, profile != "" {
                            AsyncImage(url: URL(string: profile)) { image in
                                image.resizable()
                            } placeholder: {
                                Color("MOCDarkGray")
                            }
                            .aspectRatio(contentMode: .fill)
                        } else {
                            Circle()
                                .foregroundColor(Color("MOCDarkGray"))
                        }
                    }
                    .clipShape(Circle())
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(Color("MOCDarkGray"), lineWidth: 1)
                    )
                    .onTapGesture {
                        showMypage = true
                    }
                    
                }
                
                // 채팅방 목록
                if let chatrooms = chatroomsViewModel.chatrooms, chatrooms.count > 0 {
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 20) {
                                ForEach(chatrooms) { chatroom in
                                    ChatroomBlock(data: chatroom)
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
        }
        .sheet(isPresented: $showMypage) {
            MypageView(
                userInfo: $userInfoViewModel.userInfo,
                selectImage: $selectImage,
                imageUpdated: $imageUpdated,
                isChat: $isChat,
                isCreate: $isCreate,
                isSetting: $isSetting,
                showMypage: $showMypage,
                chatroomDocId: $chatroomDocId
            )
            .presentationDragIndicator(.hidden)
            .presentationDetents([.fraction(0.82)])
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
            SettingAccountView(userInfo: $userInfoViewModel.userInfo)
        })
    }
}

//#Preview {
//    ChatListView()
//}
