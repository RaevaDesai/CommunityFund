//
//  LoginView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import Foundation
import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("First Name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            TextField("Last Name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(
                scheme: .dark,
                style: .wide,
                state: .normal
            )) {
                authVM.googleSignIn()
            }
            .padding()
            
            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
}
