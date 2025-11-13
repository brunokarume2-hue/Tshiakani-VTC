//
//  CityView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct CityView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    let cityCoordinates: [String: CLLocationCoordinate2D] = [
        "Kinshasa": CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        "Lubumbashi": CLLocationCoordinate2D(latitude: -11.6642, longitude: 27.4827),
        "Mbuji-Mayi": CLLocationCoordinate2D(latitude: -6.1360, longitude: 23.5898),
        "Kananga": CLLocationCoordinate2D(latitude: -5.8960, longitude: 22.4167),
        "Kisangani": CLLocationCoordinate2D(latitude: 0.5152, longitude: 25.1910)
    ]
    
    init() {
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Carte
            Map {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                region = MKCoordinateRegion(
                    center: context.region.center,
                    span: context.region.span
                )
            }
            .frame(height: 300)
            
            // Liste des villes
            List {
                ForEach(settingsViewModel.availableCities, id: \.self) { city in
                    Button(action: {
                        settingsViewModel.setCity(city)
                        if let coordinate = cityCoordinates[city] {
                            withAnimation {
                                region = MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                )
                            }
                        }
                    }) {
                        HStack {
                            Text(city)
                                .foregroundColor(.primary)
                            Spacer()
                            if settingsViewModel.selectedCity == city {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ville")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settingsViewModel.loadSettings()
            
            // Centrer la carte sur la ville sélectionnée
            if let coordinate = cityCoordinates[settingsViewModel.selectedCity] {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        CityView()
    }
}

