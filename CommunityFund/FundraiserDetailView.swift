//
//  FundraiserDetailView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import MapKit

struct FundraiserDetailView: View {
    let fundraiser: Fundraiser
    @State private var address: String = "Loading address..."
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    Text(fundraiser.title).font(.headline)
                    Text(fundraiser.description).font(.body)
                    Text("Goal Amount ($): \(fundraiser.goalAmount, specifier: "%.2f")")
                    Text("Organizer: \(fundraiser.organizer)")
                }
                
                Section(header: Text("Location")) {
                    Text(address)
                }
                
                Section(header: Text("Dates")) {
                    Text("Start Date: \(fundraiser.startDate, style: .date) at \(fundraiser.startDate, style: .time)")
                    Text("End Date: \(fundraiser.endDate, style: .date) at \(fundraiser.endDate, style: .time)")
                }
                
                Section {
                    Button("Donate") {
                        if let url = URL(string: fundraiser.externalDonationLink) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .navigationTitle("Fundraiser Info")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                reverseGeocode(coordinate: fundraiser.location)
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                address = "Address not available"
                return
            }
            
            if let placemark = placemarks?.first {
                let addressComponents = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }
                
                address = addressComponents.joined(separator: ", ")
            } else {
                address = "Address not found"
            }
        }
    }
}
