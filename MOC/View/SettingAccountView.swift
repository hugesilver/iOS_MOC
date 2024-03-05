//
//  SettingAccountView.swift
//  MOC
//
//  Created by 김태은 on 3/3/24.
//

import SwiftUI

struct SettingAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var showAlert: Bool = false
    @State private var isQuit: Bool = false
    
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
                            Text("계정 설정")
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
                
                List {
                    HStack {
                        Text("로그아웃")
                            .font(
                                .custom("Pretendard", size: 17)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Color("MOCBackground"))
                    .onTapGesture {
                        authViewModel.activeAlert = .areYouSureLogout
                        showAlert = true
                    }
                    
                    HStack {
                        Text("계정삭제")
                            .font(
                                .custom("Pretendard", size: 17)
                            )
                            .foregroundColor(Color("MOCRed"))
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Color("MOCBackground"))
                    .onTapGesture {
                        authViewModel.activeAlert = .areYouSureDelete
                        showAlert = true
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("MOCLightGray"))
            }
        }
        .background(Color("MOCBackground"))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            switch authViewModel.activeAlert {
            case .areYouSureLogout: return Alert(
                title: Text("확인"),
                message: Text("로그아웃 하시겠습니까?"),
                primaryButton: .default(Text("로그아웃"), action: {
                    UINavigationBar.setAnimationsEnabled(false)
                    authViewModel.signOut()
                    isQuit = true
                }),
                secondaryButton: .cancel(Text("취소"))
            )
                
            case .areYouSureDelete: return Alert(
                title: Text("경고"),
                message: Text("정말로 계정을 삭제 하시겠습니까?"),
                primaryButton: .default(Text("계정 삭제").foregroundColor(Color("MOCRed")), action: {
                    UINavigationBar.setAnimationsEnabled(false)
                    Task {
                        await authViewModel.deleteAccount()
                        isQuit = true
                    }
                }),
                secondaryButton: .cancel(Text("취소"))
            )
            }
        }
        .navigationDestination(isPresented: $isQuit, destination: {
            WelcomeView()
        })
    }
}

#Preview {
    SettingAccountView()
}
