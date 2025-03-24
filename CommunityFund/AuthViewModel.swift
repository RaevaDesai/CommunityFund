//
//  AuthViewModel.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let user = user {
                self?.fetchUserProfile(userId: user.uid)
            }
        }
    }
    
    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.errorMessage = "Missing authentication tokens"
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    self?.handleAuthError(error)
                }
            }
        }
    }
    
    private func fetchUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching profile: \(error)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self.userProfile = try snapshot.data(as: UserProfile.self)
                } catch {
                    print("Error decoding profile: \(error)")
                }
            } else {
                self.createNewUserProfile(userId: userId)
            }
        }
    }
    
    private func createNewUserProfile(userId: String) {
        let newProfile = UserProfile(
            createdFundraisers: [],
            donatedFundraisers: []
        )
        
        do {
            try db.collection("users").document(userId).setData(from: newProfile)
            self.userProfile = newProfile
        } catch {
            print("Error creating profile: \(error)")
        }
    }
    
    func addDonation(fundraiserId: String) {
            guard let userId = user?.uid else { return }
            
            db.collection("users").document(userId).updateData([
                "donatedFundraisers": FieldValue.arrayUnion([fundraiserId])
            ]) { [weak self] error in
                if let error = error {
                    print("Error updating donations: \(error)")
                } else {
                    self?.fetchUserProfile(userId: userId)
                }
            }
        }

        func removeDonation(fundraiserId: String) {
            guard let userId = user?.uid else { return }
            
            db.collection("users").document(userId).updateData([
                "donatedFundraisers": FieldValue.arrayRemove([fundraiserId])
            ]) { [weak self] error in
                if let error = error {
                    print("Error removing donation: \(error)")
                } else {
                    self?.fetchUserProfile(userId: userId)
                }
            }
        }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
            self.userProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .accountExistsWithDifferentCredential:
                errorMessage = "Account already exists with different method"
            case .invalidCredential:
                errorMessage = "Invalid authentication credentials"
            case .operationNotAllowed:
                errorMessage = "Sign-in method not enabled"
            case .emailAlreadyInUse:
                errorMessage = "Email already in use"
            case .userDisabled:
                errorMessage = "Account disabled"
            case .wrongPassword:
                errorMessage = "Incorrect credentials"
            default:
                errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
