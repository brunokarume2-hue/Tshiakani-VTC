//
//  MapLocationPickerView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct MapLocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: Location?
    @Binding var address: String
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var coordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    if let coordinate = coordinate {
                        Marker("", coordinate: coordinate)
                            .tint(.red)
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    region = MKCoordinateRegion(
                        center: context.region.center,
                        span: context.region.span
                    )
                }
                .onChange(of: region.center.latitude) { oldValue, newValue in
                    // Mettre à jour la coordonnée quand la carte est déplacée
                    coordinate = region.center
                    if let coord = coordinate {
                        updateLocation(coordinate: coord)
                    }
                }
                .onChange(of: region.center.longitude) { oldValue, newValue in
                    // Mettre à jour la coordonnée quand la carte est déplacée
                    coordinate = region.center
                    if let coord = coordinate {
                        updateLocation(coordinate: coord)
                    }
                }
                
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppColors.accentOrange.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(AppColors.accentOrange)
                    }
                    .offset(y: -20)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                if addressViewModel.isLoading {
                    VStack(spacing: AppDesign.spacingS) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(AppDesign.spacingM)
                        Text("Recherche de l'adresse...")
                            .font(AppTypography.caption(weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(AppDesign.spacingM)
                    .background(.regularMaterial)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                }
                
                // Afficher les erreurs
                if let errorMessage = addressViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Choisir une destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Text("Annuler")
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.accentOrange)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        HapticFeedback.medium()
                        if let coord = coordinate {
                            Task {
                                await addressViewModel.selectLocationFromMap(coord)
                                if let location = addressViewModel.selectedLocation {
                                    selectedLocation = location
                                    address = location.address ?? "\(coord.latitude), \(coord.longitude)"
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        Text("Confirmer")
                            .font(AppTypography.body(weight: .semibold))
                            .foregroundColor(coordinate == nil || addressViewModel.isLoading ? AppColors.secondaryText : AppColors.accentOrange)
                    }
                    .disabled(coordinate == nil || addressViewModel.isLoading)
                }
            }
            .onAppear {
                // Initialiser avec le centre de la région
                coordinate = region.center
                updateLocation(coordinate: region.center)
            }
            .onChange(of: addressViewModel.selectedLocation) { _, location in
                if let location = location, let coord = coordinate {
                    address = location.address ?? "\(coord.latitude), \(coord.longitude)"
                }
            }
        }
    }
    
    private func updateLocation(coordinate: CLLocationCoordinate2D) {
        Task {
            await addressViewModel.selectLocationFromMap(coordinate)
            if let location = addressViewModel.selectedLocation {
                await MainActor.run {
                    self.address = location.address ?? "\(coordinate.latitude), \(coordinate.longitude)"
                }
            }
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapLocationPickerView(selectedLocation: .constant(nil), address: .constant(""))
}

