//
//  ClientHomeView.swift
//  Tshiakani VTC
//
//  Vue d'accueil client simplifiée - Google Maps directement avec options essentielles
//

import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct ClientHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var rideViewModel = RideViewModel()
    
    @State private var region: MKCoordinateRegion
    @State private var pickupLocation: Location?
    @State private var dropoffLocation: Location?
    @State private var pickupAddress = ""
    @State private var dropoffAddress = ""
    @State private var showingPickupSearch = false
    @State private var showingDropoffSearch = false
    @State private var showingMapPicker = false
    @State private var navigateToRideMap = false
    @State private var navigateToSettings = false
    @State private var estimatedPrice: Double = 0
    @State private var estimatedDistance: Double = 0
    @State private var estimatedTime: Int = 0
    @State private var availableDrivers: [User] = []
    @State private var isInitialLocationSet = false
    @State private var recentDestinations: [Location] = []
    @State private var selectedVehicleType: VehicleType = .economy
    
    init() {
        // Initialiser avec Kinshasa par défaut
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    @ViewBuilder
    private var mapView: some View {
        GoogleMapView(
            region: $region,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            showsUserLocation: true,
            driverAnnotations: [],
            availableDrivers: availableDrivers,
            driverLocation: nil,
            routePolyline: nil,
            onLocationUpdate: { _ in },
            onRegionChange: { region = $0 }
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    HapticFeedback.light()
                    showingDropoffSearch = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(dropoffAddress.isEmpty ? "Où allez-vous ?" : dropoffAddress)
                            .font(AppTypography.headline(weight: .regular))
                            .foregroundColor(dropoffAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !dropoffAddress.isEmpty {
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(AppDesign.animationFast) {
                                    dropoffLocation = nil
                                    dropoffAddress = ""
                                    selectedVehicleType = .economy
                                    calculateEstimate()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .accessibilityLabel("Effacer")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                
                // Bouton paramètres dans le coin supérieur droit
                Button(action: {
                    HapticFeedback.selection()
                    navigateToSettings = true
                }) {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.accentOrange)
                    }
                }
                .accessibilityLabel("Paramètres")
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var locationButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                HapticFeedback.light()
                centerOnUserLocation()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 120)
            .accessibilityLabel("Centrer sur ma position")
        }
    }
    
    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                // Sélection de véhicule (si destination sélectionnée)
                if dropoffLocation != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choisissez un véhicule")
                            .font(AppTypography.headline(weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(VehicleType.allCases, id: \.self) { vehicleType in
                                    VehicleSelectionCard(
                                        vehicleType: vehicleType,
                                        price: calculatePrice(for: vehicleType),
                                        estimatedWaitTime: vehicleType == .economy ? 5 : vehicleType == .comfort ? 7 : 10,
                                        isSelected: selectedVehicleType == vehicleType,
                                        isFastest: vehicleType == .business
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedVehicleType = vehicleType
                                            calculateEstimate()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Informations de course
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Distance")
                                    .font(AppTypography.caption())
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text(String(format: "%.1f km", estimatedDistance))
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Temps estimé")
                                    .font(AppTypography.caption())
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("\(estimatedTime) min")
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                            }
                        }
                        
                        Divider()
                            .background(AppColors.secondaryText.opacity(0.2))
                        
                        // Prix total
                        HStack {
                            Text("Prix total")
                                .font(AppTypography.headline(weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Spacer()
                            
                            Text("\(Int(estimatedPrice)) FC")
                                .font(AppTypography.title2(weight: .bold))
                                .foregroundColor(AppColors.accentOrange)
                        }
                        
                        // Bouton Commander
                        Button(action: {
                            HapticFeedback.medium()
                            withAnimation(AppDesign.animationSnappy) {
                                navigateToRideMap = true
                            }
                        }) {
                            Text("Commander")
                                .font(AppTypography.headline(weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(
                            LinearGradient(
                                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .shadow(color: AppColors.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                mapView
                
                VStack(spacing: 0) {
                    searchBar
                    
                    // Panneau d'informations juste sous la barre de recherche
                    if dropoffLocation != nil {
                        bottomPanel
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    locationButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden) // Toolbar cachée car la navigation se fait via la barre en bas
            .sheet(isPresented: $showingPickupSearch) {
                AddressSearchView(selectedLocation: $pickupLocation, address: $pickupAddress)
            }
            .sheet(isPresented: $showingDropoffSearch) {
                AddressSearchView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .sheet(isPresented: $showingMapPicker) {
                MapLocationPickerView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(authManager)
            }
            .navigationDestination(isPresented: $navigateToRideMap) {
                Group {
                    if let dropoff = dropoffLocation, let pickup = locationManager.currentLocation ?? pickupLocation {
                        // Créer la demande de course avec le véhicule sélectionné
                        // Le prix de base sans multiplicateur (4000 FC par km)
                        let basePrice = estimatedDistance * 4000.0
                        let rideRequest = RideRequest(
                            pickupLocation: pickup,
                            dropoffLocation: dropoff,
                            selectedVehicle: selectedVehicleType,
                            estimatedPrice: basePrice,
                            estimatedDistance: estimatedDistance,
                            estimatedTime: estimatedTime
                        )
                        
                        // Naviguer vers l'écran de recherche de chauffeurs
                        SearchingDriversView(rideRequest: rideRequest)
                            .environmentObject(authViewModel)
                    } else {
                        EmptyView()
                    }
                }
            }
            .onAppear {
                // OPTIMISATION: Initialiser Google Maps de manière lazy (performance)
                initializeGoogleMapsIfNeeded()
                // Initialiser la localisation
                initializeLocation()
                // Charger l'historique des destinations
                loadRecentDestinations()
            }
            .onChange(of: dropoffLocation) { _, _ in
                // Utiliser la position actuelle comme point de départ automatiquement
                if pickupLocation == nil {
                    pickupLocation = locationManager.currentLocation
                    pickupAddress = locationManager.currentLocation?.address ?? "Position actuelle"
                }
                calculateEstimate()
                updateMapRegion()
            }
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                if let location = newLocation {
                    // Utiliser la position actuelle comme point de départ par défaut
                    if pickupLocation == nil {
                        pickupLocation = location
                        pickupAddress = location.address ?? "Position actuelle"
                        isInitialLocationSet = true
                    }
                    
                    // Centrer la carte sur la position de l'utilisateur
                    if !isInitialLocationSet {
                        centerOnLocation(location)
                        isInitialLocationSet = true
                    }
                    
                    // Recalculer l'estimation si la destination est déjà sélectionnée
                    if dropoffLocation != nil {
                        calculateEstimate()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Initialise Google Maps de manière lazy (performance optimisée)
    private func initializeGoogleMapsIfNeeded() {
        // Vérifier si déjà initialisé
        guard !GoogleMapsService.shared.initialized else {
            return
        }
        
        // Récupérer la clé API stockée
        guard let apiKey = GoogleMapsService.shared.getAPIKey() else {
            print("⚠️ Clé API Google Maps non disponible")
            return
        }
        
        // Initialiser de manière synchrone sur le thread principal
        // Cette initialisation est rapide (< 50ms) et ne bloque pas l'UI
        GoogleMapsService.shared.initialize(apiKey: apiKey)
    }
    
    private func initializeLocation() {
        // Demander l'autorisation de localisation (non-bloquant)
        locationManager.requestAuthorizationIfNeeded()
        
        // Démarrer la mise à jour de la localisation de manière asynchrone
        if locationManager.isAuthorized {
            locationManager.startUpdatingLocation()
        }
        
        // Si on a déjà une localisation, l'utiliser
        if let currentLocation = locationManager.currentLocation {
            pickupLocation = currentLocation
            pickupAddress = currentLocation.address ?? "Position actuelle"
            centerOnLocation(currentLocation)
            isInitialLocationSet = true
        }
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.userLocation else {
            if let currentLocation = locationManager.currentLocation {
                centerOnLocation(currentLocation)
            }
            return
        }
        
        let newRegion = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation {
            region = newRegion
        }
    }
    
    private func centerOnLocation(_ location: Location) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation {
            region = newRegion
        }
    }
    
    private func updateMapRegion() {
        // Utiliser la position actuelle comme point de départ si pas défini
        let pickup = pickupLocation ?? locationManager.currentLocation
        guard let pickup = pickup, let dropoff = dropoffLocation else {
            return
        }
        
        // Calculer la région pour inclure les deux points
        let centerLat = (pickup.latitude + dropoff.latitude) / 2
        let centerLon = (pickup.longitude + dropoff.longitude) / 2
        
        let latDelta = abs(pickup.latitude - dropoff.latitude) * 1.5
        let lonDelta = abs(pickup.longitude - dropoff.longitude) * 1.5
        
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
        
        withAnimation {
            region = newRegion
        }
    }
    
    private func calculateEstimate() {
        // Utiliser la position actuelle comme point de départ si pas défini
        let pickup = pickupLocation ?? locationManager.currentLocation
        guard let pickup = pickup, let dropoff = dropoffLocation else {
            estimatedPrice = 0
            estimatedDistance = 0
            estimatedTime = 0
            return
        }
        
        // Calculer la distance
        estimatedDistance = pickup.distance(to: dropoff)
        
        // Estimer le temps (environ 4.2 min/km en moyenne)
        estimatedTime = Int(estimatedDistance * 4.2)
        
        // Calculer le prix selon le type de véhicule sélectionné
        estimatedPrice = calculatePrice(for: selectedVehicleType)
    }
    
    private func calculatePrice(for vehicleType: VehicleType) -> Double {
        // Utiliser la position actuelle comme point de départ si pas défini
        let pickup = pickupLocation ?? locationManager.currentLocation
        guard let pickup = pickup, let dropoff = dropoffLocation else {
            return 0
        }
        
        // Calculer la distance
        let distance = pickup.distance(to: dropoff)
        
        // Tarif: 4000 FC par kilomètre
        let pricePerKm = 4000.0
        let baseTotal = distance * pricePerKm
        
        // Appliquer le multiplicateur selon le type de véhicule
        return baseTotal * vehicleType.multiplier
    }
    
    private func selectRecentDestination(_ destination: Location) {
        dropoffLocation = destination
        dropoffAddress = destination.address ?? "Destination"
        calculateEstimate()
        updateMapRegion()
    }
    
    private func loadRecentDestinations() {
        Task {
            if let userId = authViewModel.currentUser?.id {
                await rideViewModel.loadRideHistory(userId: userId)
                
                await MainActor.run {
                    // Extraire les destinations uniques des courses complétées
                    var destinations: [Location] = []
                    let completedRides = rideViewModel.rideHistory.filter { $0.status == .completed }
                    
                    for ride in completedRides {
                        // Ajouter la destination si elle n'existe pas déjà (comparaison par adresse)
                        let address = ride.dropoffLocation.address ?? ""
                        if !destinations.contains(where: { ($0.address ?? "") == address }) {
                            destinations.append(ride.dropoffLocation)
                        }
                    }
                    
                    // Limiter à 10 destinations les plus récentes
                    recentDestinations = Array(destinations.prefix(10))
                }
            }
        }
    }
}


// MARK: - Vehicle Selection Card

struct VehicleSelectionCard: View {
    let vehicleType: VehicleType
    let price: Double
    let estimatedWaitTime: Int
    let isSelected: Bool
    let isFastest: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            VStack(spacing: 8) {
                // Icône du véhicule
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? AppColors.accentOrange.opacity(0.15) : AppColors.secondaryBackground)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: vehicleType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                }
                
                // Nom du type
                Text(vehicleType.displayName)
                    .font(AppTypography.caption(weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.primaryText)
                
                // Prix
                Text("\(Int(price)) FC")
                    .font(AppTypography.caption2(weight: .bold))
                    .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                
                // Temps d'attente
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .medium))
                    Text("\(estimatedWaitTime) min")
                        .font(AppTypography.caption2())
                }
                .foregroundColor(AppColors.secondaryText)
                
                // Badge "Le plus rapide"
                if isFastest {
                    Text("Le plus rapide")
                        .font(AppTypography.caption2(weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accentOrange)
                        .cornerRadius(8)
                }
            }
            .frame(width: 120)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AppColors.accentOrange.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? AppColors.accentOrange : AppColors.secondaryText.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Option Button

struct HomeOptionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(AppTypography.caption(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Pill Button (style horizontal)

struct QuickPillButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                Text(label)
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.secondaryBackground)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {
    @Binding var navigateToSettings: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            // Settings (bouton unique centré)
            Button(action: {
                HapticFeedback.selection()
                navigateToSettings = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                    
                    Text("Paramètres")
                        .font(AppTypography.caption2(weight: .semibold))
                        .foregroundColor(AppColors.accentOrange)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondaryText.opacity(0.2)),
            alignment: .top
        )
    }
}

#Preview {
    ClientHomeView()
        .environmentObject(AuthViewModel())
}
