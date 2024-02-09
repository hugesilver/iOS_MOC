//
//  ContentView.swift
//  MOC
//
//  Created by 김태은 on 12/16/23.
//

import SwiftUI

struct SplashView: View {
    @ObservedObject private var viewModel = UserInfoViewModel()
    
    @State private var timer: Timer?
    @State private var seconds: Int = 0
    
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
                
                startTimer()
            }
            .navigationDestination(isPresented: $showView, destination: {
                if viewModel.user == nil {
                    WelcomeView()
                } else {
                    if viewModel.userInfo?.nickname == "" || viewModel.userInfo?.nickname == nil {
                        SignupView()
                    } else {
                        ChatListView()
                    }
                }
            })
        }
    }
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            seconds += 1
            
            if seconds >= 2{
                stopTimer()
                showView = true
            }
        }
    }
    
    private func stopTimer() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }
}

#Preview {
    SplashView()
}
