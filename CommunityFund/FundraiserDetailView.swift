import SwiftUI
import MapKit

struct FundraiserDetailView: View {
    let fundraiser: Fundraiser
    @EnvironmentObject var authVM: AuthViewModel
    @State private var address = "Loading address..."
    @State private var hasDonated: Bool
    @State private var showingLink = false
    
    init(fundraiser: Fundraiser) {
        self.fundraiser = fundraiser
        _hasDonated = State(initialValue: UserDefaults.standard.bool(forKey: "donated_\(fundraiser.id ?? "")"))
    }
    
    var body: some View {
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
                    showingLink = true
                }
                .disabled(fundraiser.externalDonationLink.isEmpty)
                .confirmationDialog("Donate", isPresented: $showingLink) {
                    if let url = URL(string: fundraiser.externalDonationLink) {
                        Link("Open Donation Page", destination: url)
                    }
                }
                
                Toggle("I donated", isOn: $hasDonated)
                    .onChange(of: hasDonated) { newValue in
                        if newValue {
                            authVM.addDonation(fundraiserId: fundraiser.id ?? "")
                        } else {
                            authVM.removeDonation(fundraiserId: fundraiser.id ?? "")
                        }
                        UserDefaults.standard.set(newValue, forKey: "donated_\(fundraiser.id ?? "")")
                    }
            }
        }
        .navigationTitle("Fundraiser Details")
        .onAppear(perform: reverseGeocode)
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
