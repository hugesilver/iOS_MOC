//
//  UserInfoViewModel.swift
//  MOC
//
//  Created by 김태은 on 1/20/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum ActiveAlert {
    case isNicknameEmpty, isNicknameNotAllowed, isNicknameExist, isError
}

@MainActor class UserInfoViewModel: ObservableObject {
    @Published var user: User?
    @Published var userInfo: UserInfoModel?
    
    @Published var showAlert: Bool = false
    @Published var activeAlert: ActiveAlert = .isError
    
    private let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            self.user = user
            Task {
                await getUserDocument(uid: user.uid)
            }
        }
    }
    
    func getUserDocument(uid: String) async -> Bool {
        let ref = db.collection("users").document(uid)
        
        do {
            userInfo = try await ref.getDocument(as: UserInfoModel.self, decoder: Firestore.Decoder())
        } catch {
            print("유저의 문서 확인 중 오류: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func validateNickname(nickname: String) -> Bool {
        let regexPattern = "^[a-zA-Z가-힣0-9]+$"
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
            let matches = regex.matches(in: nickname, options: [], range: NSRange(location: 0, length: nickname.utf16.count))
            
            return !matches.isEmpty
        } catch {
            print("정규표현식 오류: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkNickname(nickname: String) async -> Bool {
        if nickname.isEmpty {
            self.showAlert = true
            self.activeAlert = .isNicknameEmpty
        } else {
            let isValid = validateNickname(nickname: nickname)
            
            if isValid {
                // 닉네임 중복 확인
                let ref = Firestore.firestore().collection("users")
                
                do {
                    let snapshot = try await ref.whereField("nickname", isEqualTo: nickname).getDocuments()
                    
                    if snapshot.documents.isEmpty {
                        return true
                    } else {
                        self.showAlert = true
                        self.activeAlert = .isNicknameExist
                    }
                } catch {
                    print("닉네임 중복 확인 중 오류: \(error.localizedDescription)")
                    
                    self.showAlert = true
                    self.activeAlert = .isError
                }
            } else {
                self.showAlert = true
                self.activeAlert = .isNicknameNotAllowed
            }
        }
        
        return false
    }
    
    func updateNickname(nickname: String) async {
        let ref = Firestore.firestore().collection("users").document(user!.uid)
        
        do {
            try await ref.updateData(["nickname": nickname])
        } catch {
            print("닉네임 업데이트 중 오류: \(error.localizedDescription)")
            
            self.showAlert = true
            self.activeAlert = .isError
        }
    }
    
    func updateProfileImage(profileImage: UIImage) async {
        guard let imageData = profileImage.jpegData(compressionQuality: 0.5) else {
            print("이미지 jpeg로 변환 중 오류")
            
            self.showAlert = true
            self.activeAlert = .isError
            
            return
        }
        
        let storageRef = Storage.storage().reference().child("profiles/\(user!.uid)/profile_\(user!.uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { (_, error) in
            guard error == nil else {
                print("이미지 업로드 중 오류: \(error!.localizedDescription)")
                self.showAlert = true
                self.activeAlert = .isError
                return
            }
            
            
            storageRef.downloadURL { (url, error) in
                guard error == nil else {
                    print("이미지 다운로드 URL 생성 중 오류: \(error!.localizedDescription)")
                    self.showAlert = true
                    self.activeAlert = .isError
                    return
                }
                
                let ref = Firestore.firestore().collection("users").document(self.user!.uid)
                Task {
                    do {
                        try await ref.updateData(["profile_image": url?.absoluteString ?? ""])
                    } catch {
                        print("닉네임 업데이트 중 오류: \(error.localizedDescription)")
                        
                        self.showAlert = true
                        self.activeAlert = .isError
                    }
                }
            }
        }
    }
    
    func uploadUserData(nickname: String, profileImage: UIImage?) async {
        let checkNickname = await checkNickname(nickname: nickname)
        
        // 닉네임 업데이트
        if checkNickname && user != nil {
            await updateNickname(nickname: nickname)
            
            // 프로필 사진 업데이트
            if profileImage != nil {
                await updateProfileImage(profileImage: profileImage!)
            }
        }
    }
}
