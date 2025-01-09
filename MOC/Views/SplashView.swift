//
//  ContentView.swift
//  MOC
//
//  Created by 김태은 on 12/16/23.
//

import SwiftUI

struct SplashView: View {
    @StateObject var viewModel = UserInfoViewModel()
    
    @State private var showView: Bool = false
    @State private var isDone: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .padding(.bottom, 18)
                    Text("MOC")
                        .font(
                            .custom("Gmarket Sans", size: 32)
                            .weight(.bold)
                        )
                        .foregroundColor(Color("MOCYellow"))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("MOCBackground"))
            .ignoresSafeArea()
            .onAppear{
                if viewModel.user != nil {
                    Task {
                        await viewModel.getUserDocument(uid: viewModel.user!.uid)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showView = true
                }
            }
            .navigationDestination(isPresented: $showView, destination: {
                if viewModel.user == nil {
                    WelcomeView()
                } else {
                    if viewModel.userInfo?.nickname == nil {
                        WelcomeView()
                    } else {
                        if viewModel.userInfo?.nickname == "" {
                            SignupView(viewModel: viewModel)
                        } else {
                            ChatListView()
                        }
                    }
                }
            })
        }
    }
}

//#Preview {
//    SplashView()
//}
