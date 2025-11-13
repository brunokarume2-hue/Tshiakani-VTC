//
//  RideMapView.swift
//  Tshiakani VTC
//
//  Vue finale avec carte, prix, recherche de chauffeurs et confirmation
//

import SwiftUI
import MapKit

struct RideMapView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookingViewModel: BookingViewModel
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var rideViewModel = RideViewModel()
    
    let pickupLocation: Location
    let dropoffLocation: Location
    let estimatedPrice: Double
    let estimatedDistance: Double
    
    @State private var region: MKCoordinateRegion
    @State private var availableDrivers: [User] = []
    @State private var isSearchingDrivers = false
    @State private var isConfirmed = false
    @State private var currentRide: Ride?
    @State private var estimatedArrivalTime: Int = 0 // en minutes
    @State private var showingCancelConfirmation = false
    @State private var driverLocation: Location? // Position du chauffeur assigné
    @State private var driverName: String? // Nom du chauffeur assigné
    @State private var driverStatus: String? // Statut du chauffeur
    @State private var trackingTask: Task<Void, Never>? // Task pour suivre la position
    @State private var routePolyline: String? // Polyline de la route Google Maps
    @State private var selectedVehicleType: VehicleType? = .economy // Type de véhicule sélectionné
    
    init(pickupLocation: Location, dropoffLocation: Location, estimatedPrice: Double, estimatedDistance: Double) {
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.estimatedPrice = estimatedPrice
        self.estimatedDistance = estimatedDistance
        
        // Calculer la région pour centrer la carte sur l'itinéraire
        let centerLat = (pickupLocation.latitude + dropoffLocation.latitude) / 2
        let centerLon = (pickupLocation.longitude + dropoffLocation.longitude) / 2
        
        // Calculer le span pour inclure les deux points
        let latDelta = abs(pickupLocation.latitude - dropoffLocation.latitude) * 1.5
        let lonDelta = abs(pickupLocation.longitude - dropoffLocation.longitude) * 1.5
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        ))
    }
    
    var body: some View {
        ZStack {
            mapView
            bottomPanel
        }
        .alert("Annuler la course", isPresented: $showingCancelConfirmation) {
            Button("Non", role: .cancel) { }
            Button("Oui, annuler", role: .destructive) {
                cancelRide()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir annuler cette course ?")
        }
        .onAppear {
            // Charger la route entre pickup et dropoff
            loadRoute()
            // Lancer la recherche de chauffeurs immédiatement
            searchAvailableDrivers()
        }
        .onChange(of: rideViewModel.currentRide) { oldValue, newRide in
            if let ride = newRide {
                currentRide = ride
                isConfirmed = true
                
                // Écouter les changements de statut
                observeRideStatus(ride)
                
                // Si la course est acceptée et a un chauffeur, commencer à suivre sa position
                if ride.status == .accepted || ride.status == .driverArriving || ride.status == .inProgress,
                   ride.driverId != nil {
                    startTrackingDriver(rideId: ride.id)
                }
            }
        }
        .onDisappear {
            // Arrêter le suivi quand la vue disparaît
            stopTrackingDriver()
        }
    }
    
    // MARK: - Subviews
    
    private var mapView: some View {
        GoogleMapView(
            region: $region,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            showsUserLocation: true,
            driverAnnotations: [],
            availableDrivers: availableDrivers,
            driverLocation: driverLocation,
            routePolyline: routePolyline,
            onLocationUpdate: nil,
            onRegionChange: { newRegion in
                region = newRegion
            }
        )
        .ignoresSafeArea()
    }
    
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            panelContent
        }
    }
    
    @ViewBuilder
    private var panelContent: some View {
        VStack(spacing: 0) {
            dragIndicator
            if !isConfirmed {
                confirmationPanel
            } else {
                trackingPanel
            }
        }
        .background(.regularMaterial)
        .cornerRadius(AppDesign.cornerRadiusXL, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
    }
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppColors.secondaryText.opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.top, AppDesign.spacingS)
    }
    
    private var confirmationPanel: some View {
        VStack(spacing: AppDesign.spacingM) {
            routeInfo
            VehicleSelectionView(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                selectedVehicle: $selectedVehicleType
            )
            if let vehicleType = selectedVehicleType {
                priceSummary(for: vehicleType)
            }
            confirmButton
        }
        .padding(AppDesign.spacingM)
    }
    
    private var routeInfo: some View {
        VStack(spacing: AppDesign.spacingS) {
            HStack(spacing: AppDesign.spacingS) {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)
                Text(pickupLocation.address ?? "Point de départ")
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                Spacer()
            }
            Rectangle()
                .fill(AppColors.border.opacity(0.5))
                .frame(width: 1, height: 12)
                .padding(.leading, 3)
            HStack(spacing: AppDesign.spacingS) {
                Circle()
                    .fill(AppColors.error)
                    .frame(width: 8, height: 8)
                Text(dropoffLocation.address ?? "Destination")
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, AppDesign.spacingM)
        .padding(.vertical, AppDesign.spacingS)
        .background(.thinMaterial)
        .cornerRadius(AppDesign.cornerRadiusM)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func priceSummary(for vehicleType: VehicleType) -> some View {
        HStack {
            HStack(spacing: AppDesign.spacingS) {
                Image(systemName: "ruler")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                Text(String(format: "%.1f km", estimatedDistance))
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
            }
            Spacer()
            Text("\(Int(estimatedPrice * vehicleType.multiplier)) FC")
                .font(AppTypography.title3(weight: .bold))
                .foregroundColor(AppColors.accentOrange)
        }
        .padding(.horizontal, AppDesign.spacingM)
        .padding(.vertical, AppDesign.spacingS)
    }
    
    private var confirmButton: some View {
        Button(action: {
            HapticFeedback.medium()
            confirmRide()
        }) {
            HStack {
                if rideViewModel.isLoading {
                    ModernLoadingView()
                } else {
                    Text("Commander")
                        .font(AppTypography.headline(weight: .semibold))
                        .foregroundColor(.white)
                }
            }
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
        .buttonShadow()
        .disabled(rideViewModel.isLoading)
        .accessibilityLabel("Commander")
        .accessibilityHint("Confirmer la commande de course")
    }
    
    @ViewBuilder
    private var trackingPanel: some View {
        VStack(spacing: AppDesign.spacingL) {
            if let driverName = driverName, driverLocation != nil {
                driverTrackingView(driverName: driverName)
            } else {
                searchingView
            }
            cancelButton
        }
        .padding(AppDesign.spacingL)
    }
    
    private func driverTrackingView(driverName: String) -> some View {
        VStack(spacing: AppDesign.spacingM) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 48, height: 48)
                    Image(systemName: "car.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Votre chauffeur arrive")
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                    Text(driverName)
                        .font(AppTypography.subheadline(weight: .semibold))
                        .foregroundColor(AppColors.accentOrange)
                    if estimatedArrivalTime > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accentOrange)
                            Text("Arrivée estimée : \(estimatedArrivalTime) min")
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    if let status = driverStatus {
                        Text(statusText(for: status))
                            .font(AppTypography.caption())
                            .foregroundColor(AppColors.accentOrange)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .padding(AppDesign.spacingM)
            .background(.thinMaterial)
            .cornerRadius(AppDesign.cornerRadiusM)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private var searchingView: some View {
        // Vue simplifiée pour la recherche de chauffeurs dans RideMapView
        VStack(spacing: AppDesign.spacingM) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Recherche de chauffeurs...")
                .font(AppTypography.headline())
                .foregroundColor(AppColors.primaryText)
        }
        .padding(AppDesign.spacingL)
    }
    
    private var cancelButton: some View {
        Button(action: {
            HapticFeedback.heavy()
            showingCancelConfirmation = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Annuler la course")
                    .font(AppTypography.headline(weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.error,
                                    AppColors.error.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
            .cornerRadius(AppDesign.cornerRadiusL)
            .shadow(color: AppColors.error.opacity(0.4), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .accessibilityLabel("Annuler la course")
        .accessibilityHint("Annuler la course en cours")
    }
    
    private func statusText(for status: String) -> String {
        switch status {
        case "en_route_to_pickup": return "En route vers vous"
        case "on_trip": return "En course"
        default: return "Disponible"
        }
    }
    
    // MARK: - Actions
    
    /// Charge la route entre pickup et dropoff depuis Google Directions API
    private func loadRoute() {
        Task {
            do {
                let routeResult = try await GoogleDirectionsService.shared.calculateRoute(
                    from: pickupLocation,
                    to: dropoffLocation
                )
                await MainActor.run {
                    routePolyline = routeResult.polyline
                }
            } catch {
                print("Erreur lors du chargement de la route: \(error.localizedDescription)")
                // En cas d'erreur, on continue sans afficher la route
            }
        }
    }
    
    private func searchAvailableDrivers() {
        isSearchingDrivers = true
        
        Task {
            await rideViewModel.findAvailableDrivers(near: pickupLocation)
            
            await MainActor.run {
                availableDrivers = rideViewModel.availableDrivers
                isSearchingDrivers = false
                
                // Estimer le temps d'arrivée (basé sur le chauffeur le plus proche)
                if let nearestDriver = availableDrivers.first,
                   let driverLocation = nearestDriver.driverInfo?.currentLocation {
                    let distance = pickupLocation.distance(to: driverLocation)
                    estimatedArrivalTime = Int(distance * 2) // Estimation: 2 min par km
                } else {
                    estimatedArrivalTime = 5 // Par défaut: 5 minutes
                }
            }
        }
    }
    
    private func confirmRide() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            // Utiliser BookingViewModel pour confirmer la réservation
            let success = await bookingViewModel.confirmBooking()
            
            if success {
                await MainActor.run {
                    if let ride = bookingViewModel.currentRide {
                        currentRide = ride
                        isConfirmed = true
                        // Mettre à jour RideViewModel avec la course créée
                        rideViewModel.currentRide = ride
                    }
                }
            }
        }
    }
    
    private func cancelRide() {
        Task {
            await rideViewModel.cancelRide()
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func observeRideStatus(_ ride: Ride) {
        // Observer les changements de statut via RideViewModel
        // Le RideViewModel écoute déjà les changements via RealtimeService
        
        // Si la course est acceptée et a un chauffeur, commencer à suivre sa position
        if (ride.status == .accepted || ride.status == .driverArriving || ride.status == .inProgress),
           ride.driverId != nil {
            startTrackingDriver(rideId: ride.id)
        } else {
            stopTrackingDriver()
        }
    }
    
    private func startTrackingDriver(rideId: String) {
        // Arrêter la tâche existante s'il y en a une
        stopTrackingDriver()
        
        // Récupérer la position immédiatement
        fetchDriverLocation(rideId: rideId)
        
        // Créer une tâche pour interroger toutes les 3 secondes
        trackingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 secondes
                guard !Task.isCancelled else { break }
                await fetchDriverLocationAsync(rideId: rideId)
            }
        }
    }
    
    private func stopTrackingDriver() {
        trackingTask?.cancel()
        trackingTask = nil
    }
    
    private func fetchDriverLocation(rideId: String) {
        Task {
            await fetchDriverLocationAsync(rideId: rideId)
        }
    }
    
    private func fetchDriverLocationAsync(rideId: String) async {
        do {
            // Utiliser le nouvel endpoint trackDriver qui retourne aussi l'ETA
            let result = try await APIService.shared.trackDriver(rideId: rideId)
            
            await MainActor.run {
                // Animation fluide du mouvement du chauffeur sur la carte
                withAnimation(.easeInOut(duration: 0.5)) {
                    driverLocation = result.location
                    driverName = result.driverName
                    driverStatus = result.status
                }
                
                // Utiliser l'ETA calculé par le backend (plus précis)
                if let eta = result.estimatedArrivalMinutes {
                    estimatedArrivalTime = eta
                } else if let driverLocation = driverLocation {
                    // Fallback: calculer localement si le backend ne retourne pas d'ETA
                    let distance = pickupLocation.distance(to: driverLocation)
                    estimatedArrivalTime = Int(distance * 2) // Estimation: 2 min par km
                }
            }
        } catch {
            print("Erreur lors de la récupération de la position du chauffeur: \(error.localizedDescription)")
            // Ne pas arrêter le suivi en cas d'erreur, réessayer au prochain cycle
        }
    }
}


#Preview {
    RideMapView(
        pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Point de départ"),
        dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Destination"),
        estimatedPrice: 5000,
        estimatedDistance: 5.0
    )
    .environmentObject(AuthViewModel())
}

