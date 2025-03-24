//
//  LocationSearchService.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var selectedLocation: IdentifiableCoordinate?
    @Published var selectedAddress = ""
    @Published var searchQuery = ""
    
    private let completer = MKLocalSearchCompleter()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        
        $searchQuery
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.completer.queryFragment = query
            }
            .store(in: &cancellables)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results.filter {
            !$0.title.isEmpty && !$0.subtitle.isEmpty
        }
    }
    
    func selectAddress(_ address: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: address)
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            
            guard let item = response?.mapItems.first,
                  let location = item.placemark.location?.coordinate else {
                return
            }
            
            self.selectedLocation = IdentifiableCoordinate(coordinate: location)
            self.selectedAddress = [item.name, item.placemark.title]
                .compactMap { $0 }
                .joined(separator: "\n")
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self,
                  let placemark = placemarks?.first else { return }
            
            self.selectedAddress = [placemark.name, placemark.locality, placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
    }
}

extension MKLocalSearchCompletion: Identifiable {
    public var id: String {
        "\(title)-\(subtitle)"
    }
}
