//
//  ClientMapMainView.swift
//  Tshiakani VTC
//
//  Vue principale avec Google Maps chargé directement après inscription/connexion
//

import SwiftUI
import MapKit

struct ClientMapMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
    @State private var estimatedPrice: Double = 0
    @State private var estimatedDistance: Double = 0
    @State private var availableDrivers: [User] = []
    @State private var isInitialLocationSet = false
    
    init() {
        // Initialiser avec Kinshasa par défaut
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Google Maps en arrière-plan
                GoogleMapView(
                    region: $region,
                    pickupLocation: pickupLocation,
                    dropoffLocation: dropoffLocation,
                    showsUserLocation: true,
                    availableDrivers: availableDrivers,
                    routePolyline: nil,
                    onLocationUpdate: { location in
                        // Mettre à jour la position si nécessaire
                    },
                    onRegionChange: { newRegion in
                        region = newRegion
                    }
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // En-tête avec barres de recherche
                VStack(spacing: AppDesign.spacingM) {
                    // Barre de recherche pour le point de départ
                    HStack(spacing: AppDesign.spacingS) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.success)
                        
                        Button(action: {
                            showingPickupSearch = true
                        }) {
                            HStack {
                                Text(pickupAddress.isEmpty ? "Où êtes-vous ?" : pickupAddress)
                                    .font(AppTypography.body())
                                    .foregroundColor(pickupAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if !pickupAddress.isEmpty {
                                    Button(action: {
                                        pickupLocation = nil
                                        pickupAddress = ""
                                        calculateEstimate()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                            .padding(AppDesign.spacingM)
                            .background(AppColors.background)
                            .cornerRadius(AppDesign.cornerRadiusM)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppColors.success)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // Barre de recherche pour la destination
                    HStack(spacing: AppDesign.spacingS) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.error)
                        
                        Button(action: {
                            showingDropoffSearch = true
                        }) {
                            HStack {
                                Text(dropoffAddress.isEmpty ? "Où allez-vous ?" : dropoffAddress)
                                    .font(AppTypography.body())
                                    .foregroundColor(dropoffAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if !dropoffAddress.isEmpty {
                                    Button(action: {
                                        dropoffLocation = nil
                                        dropoffAddress = ""
                                        calculateEstimate()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                            .padding(AppDesign.spacingM)
                            .background(AppColors.background)
                            .cornerRadius(AppDesign.cornerRadiusM)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            showingMapPicker = true
                        }) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppColors.error)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, AppDesign.spacingM)
                .padding(.top, AppDesign.spacingM)
                .padding(.bottom, AppDesign.spacingS)
                .background(.ultraThinMaterial)
                
                Spacer()
                
                // Panneau d'informations en bas
                if pickupLocation != nil && dropoffLocation != nil {
                    VStack(spacing: AppDesign.spacingM) {
                        // Indicateur de drag
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.secondaryText.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .padding(.top, AppDesign.spacingS)
                        
                        // Informations de l'itinéraire
                        VStack(spacing: AppDesign.spacingM) {
                            // Point de départ et destination
                            VStack(spacing: AppDesign.spacingS) {
                                HStack(spacing: AppDesign.spacingM) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.success)
                                            .frame(width: 24, height: 24)
                                        
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 8, height: 8)
                                    }
                                    
                                    Text(pickupAddress)
                                        .font(AppTypography.subheadline(weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                }
                                
                                // Ligne de connexion
                                Rectangle()
                                    .fill(AppColors.border)
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 11)
                                
                                HStack(spacing: AppDesign.spacingM) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.error)
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "mappin.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(dropoffAddress)
                                        .font(AppTypography.subheadline(weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                }
                            }
                            .padding(AppDesign.spacingM)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppDesign.cornerRadiusM)
                            
                            // Estimation de prix et distance
                            if estimatedPrice > 0 {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Distance")
                                            .font(AppTypography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                        
                                        Text(String(format: "%.1f km", estimatedDistance))
                                            .font(AppTypography.subheadline(weight: .semibold))
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Prix estimé")
                                            .font(AppTypography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                        
                                        Text("\(Int(estimatedPrice)) FC")
                                            .font(AppTypography.title3(weight: .bold))
                                            .foregroundColor(AppColors.accentOrange)
                                    }
                                }
                                .padding(AppDesign.spacingM)
                                .background(AppColors.accentOrangeLight)
                                .cornerRadius(AppDesign.cornerRadiusM)
                            }
                            
                            // Bouton "Confirmer"
                            Button(action: {
                                navigateToRideMap = true
                            }) {
                                Text("Confirmer")
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                            .background(AppColors.accentOrange)
                            .cornerRadius(AppDesign.cornerRadiusL)
                            .buttonShadow()
                        }
                        .padding(AppDesign.spacingM)
                    }
                    .background(AppColors.background)
                    .cornerRadius(AppDesign.cornerRadiusXL, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPickupSearch) {
                AddressSearchView(selectedLocation: $pickupLocation, address: $pickupAddress)
            }
            .sheet(isPresented: $showingDropoffSearch) {
                AddressSearchView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .sheet(isPresented: $showingMapPicker) {
                MapLocationPickerView(selectedLocation: $dropoffLocation, address: $dropoffAddress)
            }
            .navigationDestination(isPresented: $navigateToRideMap) {
                if let pickup = pickupLocation, let dropoff = dropoffLocation {
                    RideMapView(
                        pickupLocation: pickup,
                        dropoffLocation: dropoff,
                        estimatedPrice: estimatedPrice,
                        estimatedDistance: estimatedDistance
                    )
                    .environmentObject(authViewModel)
                }
            }
            .onAppear {
                // Initialiser Google Maps et la localisation
                initializeLocation()
            }
            .onChange(of: pickupLocation) { _, _ in
                calculateEstimate()
                updateMapRegion()
            }
            .onChange(of: dropoffLocation) { _, _ in
                calculateEstimate()
                updateMapRegion()
            }
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                if let location = newLocation, !isInitialLocationSet {
                    // Utiliser la position actuelle comme point de départ par défaut
                    if pickupLocation == nil {
                        pickupLocation = location
                        pickupAddress = location.address ?? "Position actuelle"
                        isInitialLocationSet = true
                    }
                    
                    // Centrer la carte sur la position de l'utilisateur
                    centerOnLocation(location)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeLocation() {
        // Demander l'autorisation de localisation
        locationManager.requestAuthorizationIfNeeded()
        
        // Démarrer la mise à jour de la localisation
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
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
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
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
            estimatedPrice = 0
            estimatedDistance = 0
            return
        }
        
        // Calculer la distance
        estimatedDistance = pickup.distance(to: dropoff)
        
        // Estimer le prix (tarif de base: 500 CDF + 200 CDF par km)
        let basePrice = 500.0
        let pricePerKm = 200.0
        estimatedPrice = basePrice + (estimatedDistance * pricePerKm)
    }
}

#Preview {
    ClientMapMainView()
        .environmentObject(AuthViewModel())
}

