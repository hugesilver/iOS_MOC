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
    
    @State private var selectImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    @ObservedObject private var authViewModel = AuthenticationViewModel()
    
    @State private var isDone: Bool = false
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("MOCDarkGray"))
            .frame(
                width: 60,
                height: 6
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
            VStack {
                // 인디케이터
                indicator.padding()
                
                ScrollView {
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
                                if userInfo?.profile_image != nil && userInfo?.profile_image != "" {
                                    AsyncImage(url: URL(string: userInfo!.profile_image)) {
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
                            }
                            
                            photosPickerItem = nil
                        }
                        .padding(.top, 40)
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
                            Text("가입일: \(formatTimestamp(timestamp: userInfo!.signup_date))")
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
                    }
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
                    isDone = true
                }),
                secondaryButton: .cancel(Text("취소"))
            )
                
            case .areYouSureDelete: return Alert(
                title: Text("경고"),
                message: Text("정말로 계정을 삭제 하시겠습니까?"),
                primaryButton: .default(Text("계정 삭제").foregroundColor(Color("MOCRed")), action: {
                    Task {
                        await authViewModel.deleteAccount()
                        isDone = true
                    }
                }),
                secondaryButton: .cancel(Text("취소"))
            )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isDone, destination: {
            WelcomeView()
        })
    }
    
    // Timestamp 타입 변환 함수
    func formatTimestamp(timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let formattedDate = dateFormatter.string(from: timestamp.dateValue())
        return formattedDate
    }
}

//#Preview {
//    MypageView()
//}
