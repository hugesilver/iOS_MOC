//
//  WelcomeView.swift
//  MOC
//
//  Created by 김태은 on 1/17/24.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isLoading: Bool = false
    @State private var isAuthPassed: Bool = false
    
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject var userInfoViewModel = UserInfoViewModel()
    
    @State private var nickname: String?
    
    var body: some View {
        NavigationStack {
            ZStack{
                VStack(spacing: 0) {
                    // 로고
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .padding(.bottom, 20)
                    
                    // 슬로건
                    Text("모두의 오픈채팅")
                        .font(
                            .custom("Pretendard", size: 16)
                            .weight(.semibold)
                        )
                        .foregroundColor(Color("MOCTextColor"))
                    Text("MOC")
                        .font(
                            .custom("Gmarket Sans", size: 16)
                            .weight(.bold)
                        )
                        .foregroundColor(Color("MOCYellow"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // padding bottom 70 고정 버튼
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("MOCBackground"))
                        .stroke(Color("MOCDarkGray"), lineWidth: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .overlay(
                            HStack(spacing: 0) {
                                Image("LogoGoogle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .padding(.trailing, 18)
                                Text("Google 계정으로 참여하기")
                                    .font(
                                        .custom("Pretendard", size: 16)
                                        .weight(.medium)
                                    )
                                    .foregroundColor(Color("MOCDarkGray"))
                            }
                        )
                        .padding(.bottom, 70)
                        .onTapGesture {
                            isLoading = true
                            Task {
                                let signinGoogle: Bool = await authViewModel.signInWithGoogle()
                                
                                if signinGoogle {
                                    await getUserNickname()
                                }
                                
                                isLoading = false
                            }
                        }
                    
                    , alignment: .bottom
                )
                .padding(.horizontal, 50)
                .background(Color("MOCBackground"))
                .ignoresSafeArea()
                
                // 인증 처리 중 화면
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isAuthPassed, destination: {
            if nickname == "" || nickname == nil {
                SignupView(viewModel: userInfoViewModel)
            } else {
                ChatListView()
            }
        })
    }
    
    func getUserNickname() async {
        userInfoViewModel.getUser()
        
        guard let user = userInfoViewModel.user else {
            print("유저 없음")
            return
        }
        
        let userDocTask: Bool = await userInfoViewModel.getUserDocument(uid: user.uid)
        
        if userDocTask {
            if let userInfo = userInfoViewModel.userInfo {
                nickname = userInfo.nickname
            }
            
            isAuthPassed = true
        }
    }
}

#Preview {
    WelcomeView()
}
