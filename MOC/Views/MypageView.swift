//
//  MypageView.swift
//  MOC
//
//  Created by 김태은 on 2/8/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct MypageView: View {
    @Binding var userInfo: UserInfoModel?
    
    @Binding var selectImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @Binding var imageUpdated: Bool
    
    @StateObject private var chatroomsViewModel = ChatroomsViewModel()
    
    @Binding var isChat: Bool
    @Binding var isCreate: Bool
    @Binding var isSetting: Bool
    
    @Binding var showMypage: Bool
    
    @Binding var chatroomDocId: String?
    
    private let chatroomsLimit: Int = 3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 인디케이터
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("MOCDarkGray"))
                    .frame(
                        width: 60,
                        height: 8
                    )
                    .padding(.vertical, 13)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 프로필 사진
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Group {
                                if selectImage != nil {
                                    Image(uiImage: selectImage!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    if let profile = userInfo?.profile_image, profile != "" {
                                        AsyncImage(url: URL(string: profile)) {
                                            image in image.resizable()
                                        } placeholder: {
                                            Color("MOCDarkGray")
                                        }
                                        .aspectRatio(contentMode: .fill)
                                        .overlay(
                                            Circle()
                                                .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                        )
                                        .overlay(IconCamera(), alignment: .bottomTrailing)
                                    } else {
                                        Circle()
                                            .foregroundColor(Color("MOCDarkGray"))
                                    }
                                }
                            }
                            .clipShape(Circle())
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(Color("MOCDarkGray"), lineWidth: 1)
                            )
                            .overlay(IconCamera(), alignment: .bottomTrailing)
                            
                        }
                        .onChange(of: photosPickerItem) { image, _ in
                            Task {
                                guard let data = try? await image?.loadTransferable(type: Data.self) else { return }
                                selectImage = UIImage(data: data)
                                let _ = await UserInfoViewModel().updateProfileImage(profileImage: UIImage(data: data)!)
                                
                                imageUpdated = true
                            }
                            
                            photosPickerItem = nil
                        }
                        .padding(.bottom, 16)
                        
                        // 닉네임
                        Text(userInfo?.nickname ?? "unknown")
                            .font(
                                .custom("Pretendard", size: 32)
                                .weight(.bold)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                            .padding(.bottom, 4)
                        
                        // 가입일
                        if userInfo?.signup_date != nil {
                            Text("가입일: \(formatKoreanTimestamp(timestamp: userInfo!.signup_date))")
                                .font(.custom("Pretendard", size: 16))
                                .foregroundColor(Color("MOCDarkGray"))
                                .padding(.bottom, 20)
                        } else {
                            Text("가입일: 알 수 없음")
                                .font(.custom("Pretendard", size: 16))
                                .foregroundColor(Color("MOCDarkGray"))
                                .padding(.bottom, 20)
                        }
                        
                        // 로그아웃, 계정삭제 버튼
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("MOCDarkGray"))
                                
                                Text("계정 설정")
                                    .font(
                                        .custom("Pretendard", size: 12)
                                        .weight(.medium)
                                    )
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color("MOCWhite"))
                                    .padding(.vertical, 8)
                            }
                            .onTapGesture {
                                isSetting = true
                                showMypage = false
                            }
                        }
                        .padding(.bottom, 25)
                        
                        // 개설한 채팅
                        HStack(spacing: 10) {
                            Text("개설한 채팅(\(userInfo?.created_chatrooms.count ?? 0)/\(chatroomsLimit))")
                                .font(
                                    .custom("Pretendard", size: 20)
                                    .weight(.bold)
                                )
                                .foregroundColor(Color("MOCTextColor"))
                            
                            if let created_chatrooms = userInfo?.created_chatrooms, created_chatrooms.count < 3 {
                                Circle()
                                    .fill(Color("MOCYellow"))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Image("IconPlus")
                                            .resizable()
                                            .frame(width: 10, height: 10)
                                    )
                                    .onTapGesture {
                                        isCreate = true
                                        showMypage = false
                                    }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 20)
                        
                        if let chatrooms = chatroomsViewModel.created_chatrooms, chatrooms.count > 0 {
                            LazyVStack(spacing: 20) {
                                ForEach(chatrooms) { chatroom in
                                    ChatroomBlock(data: chatroom)
                                        .onTapGesture {
                                            chatroomDocId = chatroom.id
                                            isChat = true
                                            showMypage = false
                                        }
                                }
                            }
                            .padding(.bottom, 25)
                        } else {
                            EmptyView()
                                .padding(.bottom, 25)
                        }
                        
                        // 참여 중인 채팅
                        HStack(spacing: 0) {
                            Text("참여 중인 채팅")
                                .font(
                                    .custom("Pretendard", size: 20)
                                    .weight(.bold)
                                )
                                .foregroundColor(Color("MOCTextColor"))
                                .padding(.bottom, 20)
                            
                            Spacer()
                        }
                        
                        if let chatrooms = chatroomsViewModel.joined_chatrooms, chatrooms.count > 0 {
                            LazyVStack(spacing: 20) {
                                ForEach(chatrooms) { chatroom in
                                    ChatroomBlock(data: chatroom)
                                        .onTapGesture {
                                            chatroomDocId = chatroom.id
                                            isChat = true
                                            showMypage = false
                                        }
                                }
                            }
                        }
                    }
                    .padding(.top, 43)
                    .padding(.bottom, 50)
                }
            }
            .padding(.horizontal, 20)
            .background(Color("MOCBackground"))
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await chatroomsViewModel.getCreatedChatrooms()
                await chatroomsViewModel.getJoinedChatrooms()
            }
        }
    }
}

//#Preview {
//    MypageView()
//}
