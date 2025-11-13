//
//  DriversMapView.swift
//  Tshiakani VTC
//
//  Vue pour afficher les chauffeurs disponibles sur la carte avec MapKit
//

import SwiftUI
import MapKit
import CoreLocation

struct DriversMapView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var apiService = APIService.shared
    
    // État de la carte
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa par défaut
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Données des chauffeurs
    @State private var drivers: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Carte avec annotations
            Map {
                UserAnnotation()
                
                ForEach(drivers) { driver in
                    if let location = driver.driverInfo?.currentLocation {
                        Annotation(driver.name, coordinate: location.coordinate) {
                            DriverMapAnnotation(driver: driver)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                region = MKCoordinateRegion(
                    center: context.region.center,
                    span: context.region.span
                )
            }
            .ignoresSafeArea()
            .onAppear {
                requestLocationAndLoadDrivers()
            }
            
            // Overlay avec informations
            VStack {
                // En-tête avec statut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chauffeurs disponibles")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Recherche en cours...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("\(drivers.count) chauffeur\(drivers.count > 1 ? "s" : "") trouvé\(drivers.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Bouton de rafraîchissement
                    Button(action: {
                        loadDrivers()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .disabled(isLoading)
                }
                .padding()
                .background(Color.white.opacity(0.95))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Bouton pour centrer sur la position actuelle
                if locationService.currentLocation != nil {
                    HStack {
                        Spacer()
                        Button(action: {
                            centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing)
                        .padding(.bottom, 8)
                    }
                }
            }
            
            // Message d'erreur
            if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("OK") {
                            self.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Méthodes
    
    /// Demande l'autorisation de localisation et charge les chauffeurs
    private func requestLocationAndLoadDrivers() {
        // Demander l'autorisation de localisation
        locationService.requestAuthorization()
        
        // Démarrer la mise à jour de la localisation
        locationService.startUpdatingLocation()
        
        // Charger les chauffeurs après un court délai pour permettre la localisation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadDrivers()
        }
    }
    
    /// Charge les chauffeurs disponibles depuis l'API
    private func loadDrivers() {
        guard let userLocation = locationService.currentLocation else {
            errorMessage = "Localisation non disponible. Veuillez activer la localisation."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedDrivers = try await apiService.getAvailableDrivers(
                    latitude: userLocation.latitude,
                    longitude: userLocation.longitude,
                    radius: 5.0 // Rayon de 5 km
                )
                
                await MainActor.run {
                    self.drivers = fetchedDrivers
                    self.isLoading = false
                    
                    // Ajuster la région de la carte pour inclure tous les chauffeurs
                    if !fetchedDrivers.isEmpty {
                        adjustRegionToIncludeDrivers(fetchedDrivers)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Erreur lors du chargement des chauffeurs: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Centre la carte sur la position actuelle de l'utilisateur
    private func centerOnUserLocation() {
        guard let location = locationService.currentLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Recharger les chauffeurs après le recentrage
        loadDrivers()
    }
    
    /// Ajuste la région de la carte pour inclure tous les chauffeurs et la position de l'utilisateur
    private func adjustRegionToIncludeDrivers(_ drivers: [User]) {
        guard let userLocation = locationService.currentLocation else {
            // Si pas de localisation utilisateur, centrer sur les chauffeurs
            if let firstDriver = drivers.first,
               let location = firstDriver.driverInfo?.currentLocation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
            return
        }
        
        // Trouver les limites min/max des coordonnées
        var minLat = userLocation.latitude
        var maxLat = userLocation.latitude
        var minLon = userLocation.longitude
        var maxLon = userLocation.longitude
        
        for driver in drivers {
            guard let location = driver.driverInfo?.currentLocation else { continue }
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLon = min(minLon, location.longitude)
            maxLon = max(maxLon, location.longitude)
        }
        
        // Calculer le centre et le span
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max(maxLat - minLat, 0.01) * 1.5 // Ajouter 50% de marge
        let lonDelta = max(maxLon - minLon, 0.01) * 1.5
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
}

// MARK: - Annotation de chauffeur sur la carte

struct DriverMapAnnotation: View {
    let driver: User
    
    var body: some View {
        VStack(spacing: 0) {
            // Marqueur principal
            ZStack {
                let isAvailable = driver.isDriverAvailable
                Circle()
                    .fill(isAvailable ? Color.green : Color.gray)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "car.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }
            
            // Triangle pointant vers le bas
            let isAvailable = driver.isDriverAvailable
            Triangle()
                .fill(isAvailable ? Color.green : Color.gray)
                .frame(width: 10, height: 8)
                .offset(y: -2)
        }
    }
}

// MARK: - Preview

#Preview {
    DriversMapView()
}

