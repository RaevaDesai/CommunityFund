//
//  AddressSearchView.swift
//  CommunityFund
//
//  Created by Raeva Desai on 3/23/25.
//

import SwiftUI
import MapKit

struct AddressSearchView: View {
    @ObservedObject var locationService: LocationSearchService
    
    var body: some View {
        VStack {
            TextField("Search Address", text: $locationService.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(locationService.searchResults) { result in
                        Button(action: { locationService.selectAddress(result) }) {
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
        }
    }
}

