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
    
    @StateObject var viewModel = UserInfoViewModel()
    
    private let maxOffset: CGFloat = UIScreen.main.bounds.height * 0.18
    private let closeOffset: CGFloat = UIScreen.main.bounds.height * 0.3
    private let minOffset: CGFloat = UIScreen.main.bounds.height
    
    @State private var showMypage = false
    @State private var mypageOffset: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    
    @GestureState private var gestureTranslation: CGFloat = 0
    
    @State var imageUpdated: Bool = false
    @State var selectImage: UIImage?
    
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
                        } else if let userInfo = viewModel.userInfo,
                                  let url = URL(string: userInfo.profile_image) {
                            AsyncImage(url: url) { image in
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
                    
                    ScrollView {
                        
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
                MypageView(userInfo: $viewModel.userInfo, selectImage: $selectImage, imageUpdated: $imageUpdated)
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
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel.user != nil {
                Task {
                    await viewModel.getUserDocument(uid: viewModel.user!.uid)
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
        
    }
}

//#Preview {
//    ChatListView()
//}
