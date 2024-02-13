//
//  ChatView.swift
//  MOC
//
//  Created by 김태은 on 2/13/24.
//

import SwiftUI

struct ChatView: View {
    @State private var text: String = ""
    
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
                    
                    Spacer()
                        .overlay(
                            Text("Test")
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
                
                ScrollView {
                    
                }
                
                // 입력창
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("MOCWhite"))
                    .stroke(Color("MOCDarkGray"), lineWidth: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 33)
                    .overlay(
                        HStack(spacing: 7) {
                            TextField("", text: $text)
                                .background(Color("MOCBackground")).font(
                                    .custom("Pretendard", size: 15)
                                )
                                .foregroundColor(Color("MOCTextColor"))
                                .multilineTextAlignment(.leading)
                                .onChange(of: text) { _, _ in
                                    text = String(text.prefix(8))
                                }
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("MOCYellow"))
                                .frame(width: 31, height: 23)
                                .overlay(
                                    Image("IconCamera")
                                        .resizable()
                                        .frame(width: 14.5, height: 11.6)
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("MOCBlue"))
                                .frame(width: 31, height: 23)
                                .overlay(
                                    Image("IconPlane")
                                        .resizable()
                                        .frame(width: 14.5, height: 11.6)
                                )
                        }
                            .padding(.horizontal, 10)
                    )
                    .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

#Preview {
    ChatView()
}
