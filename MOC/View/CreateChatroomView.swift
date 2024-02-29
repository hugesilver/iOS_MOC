//
//  CreateChatroomView.swift
//  MOC
//
//  Created by 김태은 on 3/1/24.
//

import SwiftUI
import PhotosUI

struct CreateChatroomView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isLoading: Bool = false
    
    @State var selectImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var title: String = ""
    
    @State private var isDone: Bool = false
    
    @StateObject private var chatroomsViewModel = ChatroomsViewModel()
    
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
            ZStack {
                VStack(spacing: 0) {
                    HStack {
                        Image("IconClose")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .onTapGesture {
                                if !isLoading {
                                    isDone = true
                                }
                            }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 텍스트
                    Text("채팅방을 설정해보아요!")
                        .font(
                            .custom("Pretendard", size: 24)
                            .weight(.bold)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("MOCTextColor"))
                        .padding(.bottom, 80)
                    
                    // 썸네일 사진 선택
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
                    .onChange(of: photosPickerItem) { image, _ in
                        Task {
                            guard let data = try? await image?.loadTransferable(type: Data.self) else { return }
                            selectImage = UIImage(data: data)
                        }
                        
                        photosPickerItem = nil
                    }
                    .padding(.bottom, 90)
                    
                    // 제목 작성란
                    TextField("", text: $title, prompt: Text("제목을 입력하세요 (최대 15자)")
                        .foregroundColor(Color("MOCLightGray")))
                    .background(Color("MOCBackground")).font(
                        .custom("Pretendard", size: 21)
                        .weight(.medium)
                    )
                    .foregroundColor(Color("MOCTextColor"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 9)
                    .padding(.horizontal, 30)
                    .overlay(
                        Rectangle()
                            .foregroundColor(Color("MOCTextColor"))
                            .frame(height: 2)
                            .padding(.horizontal, 30)
                        , alignment: .bottom
                    )
                    .onChange(of: title) { _, _ in
                        title = String(title.prefix(14))
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 80)
                // padding bottom 70 고정 버튼
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isLoading ? Color("MOCLightGray") : Color("MOCYellow"))
                        .stroke(isLoading ? Color("MOCLightGray") : Color("MOCYellow"), lineWidth: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .overlay(
                            Text("완료")
                                .font(
                                    .custom("Pretendard", size: 20)
                                    .weight(.bold)
                                )
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color("MOCTextColor"))
                        )
                        .padding(.horizontal, 30)
                        .padding(.bottom, 70)
                        .onTapGesture {
                            if !isLoading {
                                isLoading = true
                                Task {
                                    let uploadTask = await chatroomsViewModel.createChatroom(title: title, thumbnail: selectImage)
                                    if uploadTask {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isDone = true
                                        }
                                    }
                                }
                            }
                        }
                    , alignment: .bottom
                )
                .padding(.horizontal, 20)
                
                // 프로필 업데이트 처리 중 화면
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
            .background(Color("MOCBackground"))
        }
        .onChange(of: isDone) {
            if isDone {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

#Preview {
    CreateChatroomView()
}
