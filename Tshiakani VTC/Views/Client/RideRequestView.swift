//
//  RideRequestView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct RideRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var rideViewModel = RideViewModel()
    @State private var pickupLocation: Location?
    @State private var dropoffLocation: Location?
    @State private var pickupAddress = ""
    @State private var dropoffAddress = ""
    @State private var showingMap = false
    @State private var showingPickupMap = false
    @State private var showingAddressSearch = false
    @State private var showingPickupSearch = false
    @State private var estimatedPrice: Double = 0
    @State private var estimatedDistance: Double = 0
    @State private var estimatedWaitTime: Int = 0 // en minutes
    @State private var isAutoDetecting = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section Point de départ
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Point de départ")
                                .font(.headline)
                        }
                        
                        // Champ adresse de départ
                        HStack {
                            TextField("Adresse de départ", text: $pickupAddress)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .onTapGesture {
                                    showingPickupSearch = true
                                }
                            
                            if isAutoDetecting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Button(action: autoDetectPickupLocation) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        // Bouton utiliser position actuelle amélioré
                        UseCurrentLocationButton(
                            action: autoDetectPickupLocation,
                            isLoading: isAutoDetecting,
                            address: pickupAddress.isEmpty ? nil : pickupAddress
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Section Destination
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            Text("Destination")
                                .font(.headline)
                        }
                        
                        // Champ adresse de destination
                        HStack {
                            TextField("Où allez-vous ?", text: $dropoffAddress)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .onTapGesture {
                                    showingAddressSearch = true
                                }
                            
                            Button(action: { showingMap = true }) {
                                Image(systemName: "map")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Bouton choisir sur la carte
                        Button(action: { showingMap = true }) {
                            HStack {
                                Image(systemName: "map.circle.fill")
                                Text("Choisir sur la carte")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Section Estimation
                    if estimatedPrice > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Estimation")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "ruler")
                                        .foregroundColor(.blue)
                                    Text("Distance")
                                    Spacer()
                                    Text("\(String(format: "%.1f", estimatedDistance)) km")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.green)
                                    Text("Temps d'attente")
                                    Spacer()
                                    Text("\(estimatedWaitTime) min")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(AppColors.accentOrange)
                                    Text("Prix estimé")
                                    Spacer()
                                    Text(estimatedPrice.formatCurrency())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.accentOrange)
                                }
                            }
                            .padding()
                            .background(AppColors.accentOrangeVeryLight)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Nouvelle course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmer") {
                        requestRide()
                    }
                    .fontWeight(.semibold)
                    .disabled(pickupLocation == nil || dropoffLocation == nil || estimatedPrice == 0)
                }
            }
            .sheet(isPresented: $showingMap) {
                MapLocationPickerView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .sheet(isPresented: $showingAddressSearch) {
                GooglePlacesAutocompleteView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .sheet(isPresented: $showingPickupSearch) {
                GooglePlacesAutocompleteView(selectedLocation: $pickupLocation, address: $pickupAddress)
            }
            .onAppear {
                // Automatiser l'adresse de départ au chargement
                autoDetectPickupLocation()
            }
            .onChange(of: pickupLocation) { _, _ in
                calculatePrice()
            }
            .onChange(of: dropoffLocation) { _, _ in
                calculatePrice()
            }
        }
    }
    
    private func autoDetectPickupLocation() {
        isAutoDetecting = true
        
        // Si on a déjà une position actuelle, l'utiliser
        if let current = locationManager.currentLocation {
            pickupLocation = current
            pickupAddress = current.address ?? "Position actuelle"
            isAutoDetecting = false
            calculatePrice()
            return
        }
        
        // Sinon, démarrer la mise à jour de la localisation
        if !locationManager.isAuthorized {
            locationManager.requestAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        
        // Attendre la localisation (avec timeout)
        Task {
            var attempts = 0
            while attempts < 20 && locationManager.currentLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
                attempts += 1
            }
            
            await MainActor.run {
                if let current = locationManager.currentLocation {
                    pickupLocation = current
                    pickupAddress = current.address ?? "Position actuelle"
                } else {
                    pickupAddress = "Localisation en cours..."
                }
                isAutoDetecting = false
                calculatePrice()
            }
        }
    }
    
    @State private var priceCalculationTask: Task<Void, Never>?
    
    private func calculatePrice() {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
            estimatedPrice = 0
            estimatedDistance = 0
            estimatedWaitTime = 0
            return
        }
        
        // Annuler la tâche précédente si elle existe (debouncing)
        priceCalculationTask?.cancel()
        
        // 🧠 Utiliser Google Directions API pour calculer le prix avec trafic en temps réel
        priceCalculationTask = Task {
            // Attendre 300ms avant de faire l'appel (debouncing)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Vérifier si la tâche a été annulée
            guard !Task.isCancelled else { return }
            
            do {
                // Utiliser Google Directions pour obtenir distance et temps avec trafic
                let priceEstimate = try await GoogleDirectionsService.shared.estimatePrice(
                    from: pickup,
                    to: dropoff
                )
                
                // Vérifier à nouveau si annulé
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    estimatedDistance = priceEstimate.distance
                    estimatedPrice = priceEstimate.estimatedPrice
                    estimatedWaitTime = priceEstimate.duration
                }
            } catch {
                // En cas d'erreur, utiliser le calcul local comme fallback
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    estimatedDistance = pickup.distance(to: dropoff)
                    estimatedPrice = locationManager.estimatePrice(distance: estimatedDistance)
                    estimatedWaitTime = max(5, Int(estimatedDistance * 1.0) + 5)
                }
                
                // Essayer aussi l'API backend comme fallback secondaire
                Task {
                    do {
                        let priceEstimate = try await APIService.shared.estimatePrice(
                            pickup: pickup,
                            dropoff: dropoff,
                            distance: estimatedDistance
                        )
                        await MainActor.run {
                            estimatedPrice = priceEstimate.price
                        }
                    } catch {
                        print("Erreur API backend: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func requestRide() {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            await rideViewModel.requestRide(pickup: pickup, dropoff: dropoff, userId: userId)
            if rideViewModel.currentRide != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    RideRequestView()
        .environmentObject(AuthViewModel())
}
