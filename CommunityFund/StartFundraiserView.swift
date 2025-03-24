import SwiftUI
import FirebaseFirestore


struct StartFundraiserView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fundraiserManager: FundraiserManager
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var locationService = LocationSearchService()
    
    // Form fields
    @State private var title = ""
    @State private var description = ""
    @State private var goalAmount = ""
    @State private var organizer = ""
    @State private var externalLink = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fundraiser Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                    TextField("Goal Amount", text: $goalAmount)
                        .keyboardType(.decimalPad)
                    TextField("Organizer Name", text: $organizer)
                }
                
                Section(header: Text("Donation Link")) {
                    TextField("External Link", text: $externalLink)
                        .keyboardType(.URL)
                }
                
                Section(header: Text("Location")) {
                    AddressSearchView(locationService: locationService)
                }
                
                Section {
                    Button("Create Fundraiser") {
                        createFundraiser()
                    }
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("New Fundraiser")
        }
    }
    
    private var formIsValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        Double(goalAmount) != nil &&
        !organizer.isEmpty &&
        !externalLink.isEmpty &&
        locationService.selectedLocation != nil
    }
    
    private func createFundraiser() {
        guard let user = authVM.user,
              let goal = Double(goalAmount),
              let location = locationService.selectedLocation else { return }
        
        let geoPoint = GeoPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        let newFundraiser = Fundraiser(
            title: title,
            description: description,
            goalAmount: goal,
            location: geoPoint,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30), // 30 days later
            organizer: organizer,
            externalDonationLink: externalLink,
            creatorId: user.uid,
            posts: []
        )
        
        do {
            let docRef = try Firestore.firestore().collection("fundraisers").addDocument(from: newFundraiser)

            var fundraiserWithID = newFundraiser
            fundraiserWithID.id = docRef.documentID

            fundraiserManager.fundraisers.append(fundraiserWithID)
            fundraiserManager.fundraisers.append(newFundraiser)
            dismiss()
        } catch {
            print("Error creating fundraiser: \(error)")
        }
    }
}
