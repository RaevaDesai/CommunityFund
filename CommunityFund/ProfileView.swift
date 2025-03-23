//
//  ProfileView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var createdFundraisers: [Fundraiser] = []
    @State private var donatedFundraisers: [Fundraiser] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Created Fundraisers")) {
                    ForEach(createdFundraisers) { fundraiser in
                        NavigationLink(destination: FundraiserPostsView(fundraiser: fundraiser)) {
                            VStack(alignment: .leading) {
                                Text(fundraiser.title)
                                Text("Goal: $\(fundraiser.goalAmount, specifier: "%.2f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section(header: Text("Donated Fundraisers")) {
                    ForEach(donatedFundraisers) { fundraiser in
                        NavigationLink(destination: FundraiserDetailView(fundraiser: fundraiser)) {
                            Text(fundraiser.title)
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .onAppear(perform: loadFundraisers)
            .onChange(of: authVM.userProfile) { _ in
                loadFundraisers()
            }
        }
    }
    
    private func loadFundraisers() {
        loadCreatedFundraisers()
        loadDonatedFundraisers()
    }
    
    private func loadCreatedFundraisers() {
        guard let userId = authVM.user?.uid else { return }
        
        db.collection("fundraisers")
            .whereField("creatorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                createdFundraisers = snapshot?.documents.compactMap { try? $0.data(as: Fundraiser.self) } ?? []
            }
    }
    
    private func loadDonatedFundraisers() {
        guard let donatedIds = authVM.userProfile?.donatedFundraisers else { return }
        
        db.collection("fundraisers")
            .whereField(FieldPath.documentID(), in: donatedIds)
            .addSnapshotListener { snapshot, error in
                donatedFundraisers = snapshot?.documents.compactMap { try? $0.data(as: Fundraiser.self) } ?? []
            }
    }
}

struct FundraiserPostsView: View {
    let fundraiser: Fundraiser
    @State private var posts: [Post] = []
    @State private var newPost = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            List {
                ForEach(posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.content)
                        Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                }
            }
            
            if fundraiser.creatorId == Auth.auth().currentUser?.uid {
                HStack {
                    TextField("New update...", text: $newPost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addPost) {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .padding()
            }
        }
        .navigationTitle(fundraiser.title)
        .onAppear(perform: loadPosts)
    }
    
    private func loadPosts() {
        guard let fundraiserId = fundraiser.id else { return }
        
        db.collection("fundraisers")
            .document(fundraiserId)
            .collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                posts = snapshot?.documents.compactMap { try? $0.data(as: Post.self) } ?? []
            }
    }
    
    private func addPost() {
        guard !newPost.isEmpty,
              let fundraiserId = fundraiser.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let post = Post(
            content: newPost,
            timestamp: Date(),
            fundraiserId: fundraiserId
        )
        
        do {
            try db.collection("fundraisers")
                .document(fundraiserId)
                .collection("posts")
                .addDocument(from: post)
            newPost = ""
        } catch {
            print("Error adding post: \(error)")
        }
    }
}
