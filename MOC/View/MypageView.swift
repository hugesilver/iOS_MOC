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
    
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var chatroomsViewModel = ChatroomsViewModel()
    
    @State private var isAuth: Bool = false
    @Binding var isChat: Bool
    @Binding var isCreate: Bool
    
    @Binding var chatroomDocId: String?
    
    private let chatroomsLimit: Int = 3
    
    // 섹션 인디케이터
    private var indicator: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("MOCDarkGray"))
            .frame(
                width: 60,
                height: 8
            )
    }
    
    // 카메라 아이콘
    private var iconCamera: some View {
        Circle()
            .frame(width: 32, height: 32)
            .foregroundColor(Color("MOCBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .inset(by: 0.5)
                    .stroke(Color("MOCLightGray"), lineWidth: 1)
            ).overlay(
                Image("IconCamera")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15)
            )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 인디케이터
                indicator
                    .padding(.vertical, 13)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 프로필 사진
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            if selectImage != nil {
                                Image(uiImage: selectImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Circle()
                                            .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                    )
                                    .overlay(iconCamera, alignment: .bottomTrailing)
                            } else {
                                if let profile = userInfo?.profile_image, profile != "" {
                                    AsyncImage(url: URL(string: profile)) {
                                        image in image.resizable()
                                    } placeholder: {
                                        Color("MOCDarkGray")
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Circle()
                                            .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                    )
                                    .overlay(iconCamera, alignment: .bottomTrailing)
                                } else {
                                    Circle()
                                        .frame(width: 140, height: 140)
                                        .foregroundColor(Color("MOCDarkGray"))
                                        .overlay(
                                            Circle()
                                                .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                        )
                                        .overlay(iconCamera, alignment: .bottomTrailing)
                                }
                            }
                        }
                        .onChange(of: photosPickerItem) { image, _ in
                            Task {
                                guard let data = try? await image?.loadTransferable(type: Data.self) else { return }
                                selectImage = UIImage(data: data)
                                await UserInfoViewModel().updateProfileImage(profileImage: UIImage(data: data)!)
                                
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
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("MOCDarkGray"))
                                
                                Text("로그아웃")
                                    .font(
                                        .custom("Pretendard", size: 12)
                                        .weight(.medium)
                                    )
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color("MOCWhite"))
                                    .padding(.vertical, 8)
                            }
                            .onTapGesture {
                                authViewModel.activeAlert = .areYouSureLogout
                                authViewModel.showAlert = true
                            }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("MOCRed"))
                                
                                Text("계정 삭제")
                                    .font(
                                        .custom("Pretendard", size: 12)
                                        .weight(.medium)
                                    )
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color("MOCWhite"))
                                    .padding(.vertical, 8)
                            }
                            .onTapGesture {
                                Task {
                                    authViewModel.activeAlert = .areYouSureDelete
                                    authViewModel.showAlert = true
                                }
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
                                            .frame(width: 10, height: 10)
                                    )
                                    .onTapGesture {
                                        isCreate = true
                                    }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 20)
                        
                        if let chatrooms = chatroomsViewModel.created_chatrooms, chatrooms.count > 0 {
                            LazyVStack(spacing: 20) {
                                ForEach(chatrooms, id: \.id) { chatroom in
                                    chatroomBlock(data: chatroom)
                                        .onTapGesture {
                                            chatroomDocId = chatroom.id
                                            isChat = true
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
                                ForEach(chatrooms, id: \.id) { chatroom in
                                    chatroomBlock(data: chatroom)
                                        .onTapGesture {
                                            chatroomDocId = chatroom.id
                                            isChat = true
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
        .alert(isPresented: $authViewModel.showAlert) {
            switch authViewModel.activeAlert {
            case .areYouSureLogout: return Alert(
                title: Text("확인"),
                message: Text("로그아웃 하시겠습니까?"),
                primaryButton: .default(Text("로그아웃"), action: {
                    authViewModel.signOut()
                    isAuth = true
                }),
                secondaryButton: .cancel(Text("취소"))
            )
                
            case .areYouSureDelete: return Alert(
                title: Text("경고"),
                message: Text("정말로 계정을 삭제 하시겠습니까?"),
                primaryButton: .default(Text("계정 삭제").foregroundColor(Color("MOCRed")), action: {
                    Task {
                        await authViewModel.deleteAccount()
                        isAuth = true
                    }
                }),
                secondaryButton: .cancel(Text("취소"))
            )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isAuth, destination: {
            WelcomeView()
        })
        .onAppear {
            Task {
                await chatroomsViewModel.getCreatedChatrooms()
                await chatroomsViewModel.getJoinedChatrooms()
            }
        }
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
    
    // Timestamp 타입 변환 함수
    func formatKoreanTimestamp(timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let formattedDate = dateFormatter.string(from: timestamp.dateValue())
        return formattedDate
    }
}

//#Preview {
//    MypageView()
//}
