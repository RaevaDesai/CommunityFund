//
//  IdentifiableCoordinate.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import MapKit

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

