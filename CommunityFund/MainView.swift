//
//  MainView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import MapKit

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var locationManager = LocationManager()
    @StateObject private var fundraiserManager = FundraiserManager() // Fundraiser manager to track fundraisers
    @State private var showingFundraiserSheet = false
    @State private var selectedFundraiser: Fundraiser? // Selected fundraiser for detail view
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    
    
    var body: some View {
        ZStack {
            // Map with annotations for fundraisers
            Map(
                coordinateRegion: $mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: fundraiserManager.fundraisers
            ) { fundraiser in
                MapAnnotation(coordinate: fundraiser.location) {
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
            
            VStack {
                Spacer()
                
                // "+" Button to open StartFundraiserView
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
        // Update map region when user location changes
        .onReceive(locationManager.$userLocation) { location in
            if let location = location {
                mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: mapRegion.span
                )
            }
        }
        // Show StartFundraiserView as a sheet
        .sheet(isPresented: $showingFundraiserSheet) {
            StartFundraiserView().environmentObject(fundraiserManager)
        }
        // Show fundraiser details when a pin is tapped
        .sheet(item: $selectedFundraiser) { fundraiser in
            FundraiserDetailView(fundraiser: fundraiser)
        }

    }
}

// Location manager to track user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
    }
}

// Fundraiser manager to store and manage fundraisers
class FundraiserManager: ObservableObject {
    @Published var fundraisers: [Fundraiser] = []
    
    func addFundraiser(_ fundraiser: Fundraiser) {
        fundraisers.append(fundraiser)
    }
}


struct Fundraiser: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let goalAmount: Double
    let location: CLLocationCoordinate2D
    let startDate: Date
    let endDate: Date
    let organizer: String
    let externalDonationLink: String
}
