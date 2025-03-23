import Foundation
import FirebaseFirestore
import MapKit

struct UserProfile: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var createdFundraisers: [String]
    var donatedFundraisers: [String]
}

struct Fundraiser: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let goalAmount: Double
    let location: GeoPoint
    let startDate: Date
    let endDate: Date
    let organizer: String
    let externalDonationLink: String
    let creatorId: String
    var posts: [Post]
}

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    let content: String
    let timestamp: Date
    let fundraiserId: String
}
