//
//  DriversMapViewOptimized.swift
//  Tshiakani VTC
//
//  Vue SwiftUI moderne et optimisée pour afficher les chauffeurs disponibles sur la carte
//  Utilise LocationManager pour la localisation du client et DriversService pour l'API
//

import SwiftUI
import MapKit
import CoreLocation

struct DriversMapViewOptimized: View {
    // MARK: - Services et Managers
    
    @StateObject private var locationManager = LocationManager.shared
    private let apiService = APIService.shared
    
    // MARK: - État de la carte
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa par défaut
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var drivers: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Carte principale
            mapView
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                headerView
                Spacer()
                bottomControls
            }
            
            // Messages d'erreur
            if showError, let error = errorMessage {
                errorBanner(error)
            }
        }
        .onAppear {
            setupLocationAndLoadDrivers()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                handleLocationUpdate(location)
            }
        }
    }
    
    // MARK: - Vue de la carte
    
    private var mapView: some View {
        Map {
            UserAnnotation()
            
            ForEach(drivers) { driver in
                if let location = driver.driverInfo?.currentLocation {
                    Annotation(driver.name, coordinate: location.coordinate) {
                        DriverAnnotationView(driver: driver)
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
    }
    
    // MARK: - En-tête
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
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
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(drivers.count) disponible\(drivers.count > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Bouton de rafraîchissement
            Button(action: {
                Task {
                    await loadDrivers()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .disabled(isLoading)
            .rotationEffect(.degrees(isLoading ? 360 : 0))
            .animation(isLoading ? 
                      Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                      .default, value: isLoading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Contrôles du bas
    
    private var bottomControls: some View {
        HStack {
            // Bouton pour centrer sur la position utilisateur
            if locationManager.userLocation != nil {
                Button(action: {
                    centerOnUserLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Bannière d'erreur
    
    private func errorBanner(_ error: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Button("OK") {
                    showError = false
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Méthodes
    
    /// Configure la localisation et charge les chauffeurs au démarrage
    private func setupLocationAndLoadDrivers() {
        // Demander l'autorisation si nécessaire
        locationManager.requestAuthorizationIfNeeded()
        
        // Démarrer la mise à jour de la localisation
        if locationManager.isAuthorized {
            locationManager.startUpdatingLocation()
        }
        
        // Charger les chauffeurs après un court délai
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 secondes
            await loadDrivers()
        }
    }
    
    /// Charge les chauffeurs disponibles
    @MainActor
    private func loadDrivers() async {
        // Obtenir les coordonnées du client
        guard let clientLocation = getClientLocation() else {
            errorMessage = "Localisation non disponible"
            showError = true
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // Utiliser l'API pour récupérer les chauffeurs
            let fetchedDrivers = try await apiService.getAvailableDrivers(
                latitude: clientLocation.latitude,
                longitude: clientLocation.longitude,
                radius: 5.0
            )
            
            drivers = fetchedDrivers
            
            // Ajuster la région de la carte
            if !drivers.isEmpty {
                adjustRegionToShowAllDrivers()
            }
            
            isLoading = false
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    /// Obtient la localisation actuelle du client
    private func getClientLocation() -> (latitude: Double, longitude: Double)? {
        // Priorité 1: userLocation (coordonnées CLLocationCoordinate2D)
        if let userLocation = locationManager.userLocation {
            return (userLocation.latitude, userLocation.longitude)
        }
        
        // Priorité 2: currentLocation (objet Location)
        if let currentLocation = locationManager.currentLocation {
            return (currentLocation.latitude, currentLocation.longitude)
        }
        
        return nil
    }
    
    /// Gère la mise à jour de la localisation
    private func handleLocationUpdate(_ location: Location) {
        // Centrer la carte sur la nouvelle position si c'est la première localisation
        if region.center.latitude == -4.3276 && region.center.longitude == 15.3136 {
            centerOnUserLocation()
        }
        
        // Recharger les chauffeurs si on a déjà des données
        if !drivers.isEmpty {
            Task {
                await loadDrivers()
            }
        }
    }
    
    /// Centre la carte sur la position de l'utilisateur
    private func centerOnUserLocation() {
        guard let location = getClientLocation() else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Recharger les chauffeurs après le recentrage
        Task {
            await loadDrivers()
        }
    }
    
    /// Ajuste la région de la carte pour afficher tous les chauffeurs et la position de l'utilisateur
    private func adjustRegionToShowAllDrivers() {
        guard let clientLocation = getClientLocation() else {
            // Si pas de localisation client, centrer sur le premier chauffeur
            if let firstDriver = drivers.first,
               let location = firstDriver.driverInfo?.currentLocation {
                withAnimation(.easeInOut(duration: 0.5)) {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
            return
        }
        
        // Trouver les limites min/max des coordonnées
        var minLat = clientLocation.latitude
        var maxLat = clientLocation.latitude
        var minLon = clientLocation.longitude
        var maxLon = clientLocation.longitude
        
        for driver in drivers {
            guard let location = driver.driverInfo?.currentLocation else { continue }
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLon = min(minLon, location.longitude)
            maxLon = max(maxLon, location.longitude)
        }
        
        // Calculer le centre et le span avec marge
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max(maxLat - minLat, 0.01) * 1.5 // 50% de marge
        let lonDelta = max(maxLon - minLon, 0.01) * 1.5
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
}

// MARK: - Vue d'annotation pour les chauffeurs

struct DriverAnnotationView: View {
    let driver: User
    @State private var isSelected = false
    
    var body: some View {
        let isAvailable = driver.isDriverAvailable
        
        return VStack(spacing: 0) {
            // Marqueur principal
            ZStack {
                // Cercle de fond avec ombre
                Circle()
                    .fill(isAvailable ? 
                          Color.green.gradient : 
                          Color.gray.gradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // Bordure
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                // Icône
                Image(systemName: isAvailable ? "car.fill" : "car.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            // Triangle pointant vers le bas
            Triangle()
                .fill(isAvailable ? Color.green : Color.gray)
                .frame(width: 12, height: 10)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            withAnimation {
                isSelected.toggle()
            }
            
            // Désélectionner après 2 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isSelected = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DriversMapViewOptimized()
}

