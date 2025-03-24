import SwiftUI
import MapKit
import FirebaseFirestore

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var locationManager = LocationManager()
    @StateObject private var fundraiserManager = FundraiserManager()
    @State private var showingFundraiserSheet = false
    @State private var selectedFundraiser: Fundraiser?
    
    var body: some View {
        ZStack {
            if let region = locationManager.region {
                Map(
                    coordinateRegion: Binding(
                        get: { region },
                        set: { locationManager.region = $0 }
                    ),
                    showsUserLocation: true,
                    annotationItems: fundraiserManager.fundraisers
                ) { fundraiser in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: fundraiser.location.latitude,
                        longitude: fundraiser.location.longitude
                    )) {
                        Image(systemName: "mappin.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                            .onTapGesture {
                                selectedFundraiser = fundraiser
                            }
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("Loading map...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }

            VStack {
                HStack {
                    Spacer()
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                    }
                }
                Spacer()
                
                Button(action: { showingFundraiserSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingFundraiserSheet) {
            StartFundraiserView()
                .environmentObject(fundraiserManager)
        }
        .sheet(item: $selectedFundraiser) { fundraiser in
            FundraiserDetailView(fundraiser: fundraiser)
        }
    }
}
