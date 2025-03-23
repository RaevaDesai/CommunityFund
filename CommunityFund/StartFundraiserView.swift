//
//  StartFundraiserView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import MapKit

struct StartFundraiserView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fundraiserManager: FundraiserManager
    @StateObject private var locationService = LocationSearchService()
    
    @State private var title = ""
    @State private var description = ""
    @State private var goalAmount = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var organizer = ""
    @State private var externalDonationLink = ""
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selection: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fundraiser Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                    TextField("Goal Amount ($)", text: $goalAmount)
                        .keyboardType(.decimalPad)
                    TextField("Organizer Name", text: $organizer)
                }
                
                Section(header: Text("Donation Link")) {
                    TextField("External Donation URL", text: $externalDonationLink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Picker("Location Method", selection: $selection, content: {
                    Text("Search Address").tag(0)
                    Text("Drop Pin").tag(1)
                })) {
                    if selection == 0 {
                        AddressSearchView(locationService: locationService)
                    } else {
                        LocationMapView(
                            locationService: locationService,
                            region: $mapRegion
                        )
                        .frame(height: 300)
                    }
                    
                    if !locationService.selectedAddress.isEmpty {
                        Text(locationService.selectedAddress)
                            .font(.caption)
                            .padding(.vertical)
                    }
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Button("Create Fundraiser") {
                        createFundraiser()
                    }
                }
            }
            .navigationTitle("Start a Fundraiser")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createFundraiser() {
        guard let goalAmountDouble = Double(goalAmount),
              let coordinate = locationService.selectedLocation?.coordinate else {
            return
        }
        
        let newFundraiser = Fundraiser(
            id: UUID(),
            title: title,
            description: description,
            goalAmount: goalAmountDouble,
            location: coordinate,
            startDate: startDate,
            endDate: endDate,
            organizer: organizer,
            externalDonationLink: externalDonationLink
        )
        
        fundraiserManager.addFundraiser(newFundraiser)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddressSearchView: View {
    @ObservedObject var locationService: LocationSearchService
    
    var body: some View {
        VStack {
            TextField("Search Address", text: $locationService.searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            List {
                ForEach(locationService.searchResults) { result in
                    Button {
                        locationService.selectAddress(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.body)
                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 200)
        }
    }
}

struct LocationMapView: View {
    @ObservedObject var locationService: LocationSearchService
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            annotationItems: locationService.selectedLocation != nil ? [locationService.selectedLocation!] : [],
            annotationContent: { coordinate in
                MapAnnotation(coordinate: coordinate.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                }
            }
        )
        .onTapGesture {
            let newCoordinate = IdentifiableCoordinate(coordinate: region.center)
            locationService.selectedLocation = newCoordinate
            locationService.reverseGeocode(coordinate: newCoordinate.coordinate)
        }
    }
}
