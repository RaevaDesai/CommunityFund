//
//  ContentView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if authVM.user != nil {
                    MainView()
                } else {
                    LoginView()
                }
            }
            .animation(.default, value: authVM.user)
        }
    }
}

