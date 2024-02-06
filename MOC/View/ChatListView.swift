//
//  ChatListView.swift
//  MOC
//
//  Created by 김태은 on 2/7/24.
//

import SwiftUI

struct ChatListView: View {
    init() {
        UINavigationBar.setAnimationsEnabled(false)
    }
    
    @ObservedObject var viewModel = UserInfoViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack(alignment: .center) {
                        Text("채팅")
                            .font(
                                .custom("Pretendard", size: 36)
                                .weight(.bold)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                        Spacer()
                        if viewModel.userInfo?.profile_image != nil && viewModel.userInfo?.profile_image != "" {
                            AsyncImage(url: URL(string: viewModel.userInfo!.profile_image)) {
                                image in image.resizable()
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
                        } else {
                            Circle()
                                .frame(width: 42, height: 42)
                                .foregroundColor(Color("MOCDarkGray"))
                                .overlay(
                                    Circle()
                                        .stroke(Color("MOCDarkGray"), lineWidth: 1)
                                )
                        }
                        
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

#Preview {
    ChatListView()
}
