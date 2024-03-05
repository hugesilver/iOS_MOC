//
//  AuthenticationViewModel.swift
//  MOC
//
//  Created by 김태은 on 1/19/24.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

@MainActor
class AuthenticationViewModel: ObservableObject {
    enum AuthenticationError: Error {
        case tokenError(message: String)
    }
    
    enum ActiveAlert {
        case areYouSureLogout, areYouSureDelete
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @Published var activeAlert: ActiveAlert = .areYouSureLogout
    
    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No cliend ID found in Firebase configuration")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("There is no root view controller")
            return false
        }
        
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "ID token missing")
            }
            
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            
            print("\(firebaseUser.uid) 유저 \(firebaseUser.email ?? "unknown") 로그인 성공 ")
            
            let isUserInfoExist = await UserInfoViewModel().getUserDocument(uid: firebaseUser.uid)
            
            if !isUserInfoExist {
                print("작동하는 중")
                await createUserDocument(user: firebaseUser)
            }
            
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        // return false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error)
        }
    }
    
    func deleteAccount() async {
        do {
            try await Auth.auth().currentUser?.delete()
            try Auth.auth().signOut()
        } catch {
            print(error)
        }
    }
    
    func createUserDocument(user: User) async {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(user.uid)
        
        do {
            try await ref.setData([
                "uid": user.uid,
                "nickname": "",
                "profile_image": user.photoURL?.absoluteString ?? "",
                "signup_date": Date(),
                "joined_chatrooms": [],
                "created_chatrooms": []
            ])
            print("초기 유저 정보 생성 성공")
        } catch {
            print("문서 생성 중 실패: \(error.localizedDescription)")
        }
    }
}
