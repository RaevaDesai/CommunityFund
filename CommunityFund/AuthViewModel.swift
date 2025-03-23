//
//  AuthViewModel.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
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
            
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    self?.handleAuthError(error)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
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
