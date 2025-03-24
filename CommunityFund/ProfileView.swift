//
//  ProfileView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Created Fundraisers")) {
                    ForEach(viewModel.createdFundraisers) { fundraiser in
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
                    ForEach(viewModel.donatedFundraisers) { fundraiser in
                        NavigationLink(destination: FundraiserDetailView(fundraiser: fundraiser)) {
                            Text(fundraiser.title)
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .onAppear { viewModel.setupListeners(authVM: authVM) }
            .onDisappear { viewModel.removeListeners() }
        }
    }
}

// MARK: - Profile ViewModel
class ProfileViewModel: ObservableObject {
    @Published var createdFundraisers: [Fundraiser] = []
    @Published var donatedFundraisers: [Fundraiser] = []
    
    private var createdListener: ListenerRegistration?
    private var userDocListener: ListenerRegistration?
    private var donatedListener: ListenerRegistration?
    
    private let db = Firestore.firestore()

    func setupListeners(authVM: AuthViewModel) {
        guard let userId = authVM.user?.uid else { return }

        // Created Fundraisers Listener
        createdListener = db.collection("fundraisers")
            .whereField("creatorId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Created fundraisers error: \(error)")
                    return
                }
                self?.createdFundraisers = snapshot?.documents.compactMap {
                    try? $0.data(as: Fundraiser.self)
                } ?? []
            }

        // Donated Fundraisers Listener (refetches whenever the profile changes)
        userDocListener = db.collection("users").document(userId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("User profile error: \(error)")
                return
            }

            guard let document = document,
                  let profile = try? document.data(as: UserProfile.self) else {
                print("Failed to decode profile")
                return
            }

            self.fetchDonatedFundraisers(by: profile.donatedFundraisers)
        }
    }

    private func fetchDonatedFundraisers(by ids: [String]) {
        // Remove previous listener
        donatedListener?.remove()
        donatedFundraisers = []

        guard !ids.isEmpty else { return }

        donatedListener = db.collection("fundraisers")
            .whereField(FieldPath.documentID(), in: ids)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Donated fundraisers error: \(error)")
                    return
                }

                self?.donatedFundraisers = snapshot?.documents.compactMap {
                    try? $0.data(as: Fundraiser.self)
                } ?? []
            }
    }

    func removeListeners() {
        createdListener?.remove()
        donatedListener?.remove()
        userDocListener?.remove()
        createdListener = nil
        donatedListener = nil
        userDocListener = nil
    }
}


// MARK: - Fundraiser Posts View
struct FundraiserPostsView: View {
    let fundraiser: Fundraiser
    @StateObject private var viewModel = PostsViewModel()
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.content)
                        Text(post.timestamp, style: .date)
                            .font(.caption)
                    }
                }
            }
            
            if fundraiser.creatorId == Auth.auth().currentUser?.uid {
                HStack {
                    TextField("New update...", text: $viewModel.newPost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: viewModel.addPost) {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(viewModel.newPost.isEmpty)
                }
                .padding()
            }
        }
        .navigationTitle(fundraiser.title)
        .onAppear { viewModel.setupListener(fundraiserId: fundraiser.id ?? "") }
    }
}

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var newPost = ""

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    private var currentFundraiserId: String?

    func setupListener(fundraiserId: String) {
        currentFundraiserId = fundraiserId

        listener = db.collection("fundraisers")
            .document(fundraiserId)
            .collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.posts = snapshot?.documents.compactMap {
                    try? $0.data(as: Post.self)
                } ?? []
            }
    }

    func addPost() {
        guard !newPost.isEmpty,
              let userId = Auth.auth().currentUser?.uid,
              let fundraiserId = currentFundraiserId else { return }

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

    deinit {
        listener?.remove()
    }
}

