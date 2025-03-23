import SwiftUI
import MapKit

struct FundraiserDetailView: View {
    let fundraiser: Fundraiser
    @EnvironmentObject var authVM: AuthViewModel
    @State private var address = "Loading address..."
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    Text(fundraiser.title).font(.headline)
                    Text(fundraiser.description)
                    Text("Goal: $\(fundraiser.goalAmount, specifier: "%.2f")")
                    Text("Organizer: \(fundraiser.organizer)")
                }
                
                Section(header: Text("Location")) {
                    Text(address)
                }
                
                Section(header: Text("Dates")) {
                    Text("Starts: \(fundraiser.startDate.formatted(date: .abbreviated, time: .shortened))")
                    Text("Ends: \(fundraiser.endDate.formatted(date: .abbreviated, time: .shortened))")
                }
                
                Section {
                    Button("Donate Now") {
                        if let url = URL(string: fundraiser.externalDonationLink) {
                            UIApplication.shared.open(url)
                            authVM.addDonation(fundraiserId: fundraiser.id ?? "")
                        }
                    }
                    .disabled(fundraiser.externalDonationLink.isEmpty)
                }
            }
            .navigationTitle("Fundraiser Details")
            .onAppear(perform: reverseGeocode)
        }
    }
    
    private func reverseGeocode() {
        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: fundraiser.location.latitude,
            longitude: fundraiser.location.longitude
        )
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocode error: \(error)")
                address = "Unknown address"
                return
            }
            
            guard let placemark = placemarks?.first else {
                address = "Address not found"
                return
            }
            
            address = [
                placemark.name,
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode
            ].compactMap { $0 }.joined(separator: ", ")
        }
    }
}
