//
//  FundraiserManager.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import Foundation
import FirebaseFirestore

class FundraiserManager: ObservableObject {
    @Published var fundraisers: [Fundraiser] = []
    private let db = Firestore.firestore()
    
    init() {
        fetchFundraisers()
    }
    
    func addFundraiser(_ fundraiser: Fundraiser) {
        do {
            try db.collection("fundraisers").addDocument(from: fundraiser)
        } catch {
            print("Error adding fundraiser: \(error)")
        }
    }
    
    private func fetchFundraisers() {
        db.collection("fundraisers")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching fundraisers: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self.fundraisers = documents.compactMap { document in
                    try? document.data(as: Fundraiser.self)
                }
            }
    }
}
