//
//  SearchingDriversView.swift
//  Tshiakani VTC
//
//  Écran de recherche de chauffeurs (Image 2)
//  S'affiche après que le client a confirmé la commande
//

import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct SearchingDriversView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var rideViewModel = RideViewModel()
    @StateObject private var driverSearchViewModel: DriverSearchViewModel
    @StateObject private var mapViewModel = MapViewModel()
    
    // Modèle simplifié - toutes les données en un seul objet
    @State private var rideRequest: RideRequest
    
    @State private var showingCancelConfirmation = false
    @State private var navigateToDriverFound = false
    @State private var navigateToRideTracking = false
    
    // Initialisation simplifiée avec RideRequest
    init(rideRequest: RideRequest) {
        _rideRequest = State(initialValue: rideRequest)
        _driverSearchViewModel = StateObject(wrappedValue: DriverSearchViewModel(ride: nil, rideId: nil))
    }
    
    var body: some View {
        ZStack {
            // Carte Google Maps en arrière-plan (grisée)
            GoogleMapView(
                region: $mapViewModel.mapRegion,
                pickupLocation: rideRequest.pickupLocation,
                dropoffLocation: rideRequest.dropoffLocation,
                showsUserLocation: true,
                driverAnnotations: [],
                availableDrivers: driverSearchViewModel.availableDrivers,
                driverLocation: nil,
                routePolyline: nil, // TODO: Ajouter routePolyline à MapViewModel
                onLocationUpdate: nil,
                onRegionChange: { newRegion in
                    mapViewModel.mapRegion = newRegion
                }
            )
            .ignoresSafeArea()
            .overlay(
                // Overlay pour griser la carte
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
            )
            
            VStack(spacing: 0) {
                // Bouton d'annulation flottant en haut à gauche
                HStack {
                    Button(action: {
                        HapticFeedback.medium()
                        showingCancelConfirmation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 60)
                    .accessibilityLabel("Annuler la recherche")
                    
                    Spacer()
                }
                
                Spacer()
                
                // Panneau de recherche en bas (style Image 2)
                VStack(spacing: 0) {
                    // Indicateur de drag
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.secondaryText.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, AppDesign.spacingS)
                    
                    // Contenu du panneau (inspiré de l'image - "Searching for Driver")
                    VStack(spacing: AppDesign.spacingL) {
                        // Illustration de recherche avec animation élégante
                        VStack(spacing: AppDesign.spacingL) {
                            ZStack {
                                // Cercles concentriques animés avec effet de pulsation
                                ForEach(0..<4) { index in
                                    Circle()
                                        .stroke(
                                            AppColors.accentOrange.opacity(0.2 - Double(index) * 0.05),
                                            lineWidth: 2
                                        )
                                        .frame(width: CGFloat(60 + index * 25), height: CGFloat(60 + index * 25))
                                        .scaleEffect(driverSearchViewModel.isSearching ? 1.3 : 0.9)
                                        .opacity(driverSearchViewModel.isSearching ? 0.1 : 0.4)
                                        .animation(
                                            Animation.spring(
                                                response: 1.5,
                                                dampingFraction: 0.6,
                                                blendDuration: 0.2
                                            )
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.2),
                                            value: driverSearchViewModel.isSearching
                                        )
                                }
                                
                                // Effet de vague qui se propage
                                ForEach(0..<2) { index in
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    AppColors.accentOrange.opacity(0.1),
                                                    AppColors.accentOrange.opacity(0.0)
                                                ],
                                                center: .center,
                                                startRadius: 30,
                                                endRadius: 80
                                            )
                                        )
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(driverSearchViewModel.isSearching ? 1.5 : 0.8)
                                        .opacity(driverSearchViewModel.isSearching ? 0.0 : 0.3)
                                        .animation(
                                            Animation.easeOut(duration: 2.0)
                                                .repeatForever(autoreverses: false)
                                                .delay(Double(index) * 1.0),
                                            value: driverSearchViewModel.isSearching
                                        )
                                }
                                
                                // Icône de voiture au centre avec animation subtile
                                ZStack {
                                    Circle()
                                        .fill(AppColors.accentOrange.opacity(0.12))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(AppColors.accentOrange)
                                        .scaleEffect(driverSearchViewModel.isSearching ? 1.05 : 0.95)
                                        .rotationEffect(.degrees(driverSearchViewModel.isSearching ? 2 : -2))
                                        .animation(
                                            Animation.easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: true),
                                            value: driverSearchViewModel.isSearching
                                        )
                                }
                            }
                            .frame(height: 180)
                            .padding(.top, AppDesign.spacingM)
                            
                            // Titre et description
                            VStack(spacing: 8) {
                                Text("Recherche en cours...")
                                    .font(AppTypography.title2(weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Recherche de véhicules à proximité")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.top, AppDesign.spacingM)
                        
                        // Bouton Annuler redessiné
                        Button(action: {
                            HapticFeedback.heavy()
                            showingCancelConfirmation = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Annuler la recherche")
                                    .font(AppTypography.headline(weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
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
                            .shadow(color: AppColors.error.opacity(0.4), radius: 12, x: 0, y: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .accessibilityLabel("Annuler la recherche")
                        .accessibilityHint("Annuler la recherche de chauffeurs et retourner à l'écran d'accueil")
                    }
                    .padding(.top, AppDesign.spacingS)
                }
                .background(.regularMaterial)
                .cornerRadius(AppDesign.cornerRadiusXL, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: -4)
                .frame(maxHeight: 450)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AppDesign.animationSmooth, value: driverSearchViewModel.isSearching)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden) // Toolbar cachée car le bouton "Annuler la course" est dans le panneau
        .navigationDestination(isPresented: $navigateToDriverFound) {
            if let ride = rideViewModel.currentRide,
               let driverId = ride.driverId,
               let driver = driverSearchViewModel.availableDrivers.first(where: { $0.id == driverId }) ?? driverSearchViewModel.foundDriver {
                DriverFoundView(
                    rideRequest: rideRequest,
                    driver: driver,
                    ride: ride
                )
                .environmentObject(authViewModel)
            }
        }
        .alert("Annuler la course", isPresented: $showingCancelConfirmation) {
            Button("Non", role: .cancel) { }
            Button("Oui, annuler", role: .destructive) {
                // Annuler immédiatement et revenir à l'écran précédent
                cancelRide()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir annuler cette course ? Vous serez redirigé vers l'écran d'accueil.")
        }
        .onAppear {
            startSearch()
            loadRoute()
        }
        .onDisappear {
            stopSearch()
        }
        .onChange(of: rideViewModel.currentRide) { oldValue, newRide in
            if let ride = newRide {
                driverSearchViewModel.ride = ride
                driverSearchViewModel.rideId = ride.id
                
                if ride.status == .accepted || ride.status == .driverArriving {
                    driverSearchViewModel.isSearching = false
                    
                    // Naviguer vers l'écran d'attente du chauffeur
                    if let driverId = ride.driverId {
                        // Chercher le chauffeur dans la liste
                        if driverSearchViewModel.availableDrivers.contains(where: { $0.id == driverId }) {
                            navigateToDriverFound = true
                        } else {
                            // Si le chauffeur n'est pas dans la liste, le récupérer
                            Task {
                                driverSearchViewModel.loadDriverInfo(driverId: driverId)
                                if driverSearchViewModel.foundDriver != nil {
                                    navigateToDriverFound = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startSearch() {
        // Lancer la recherche de chauffeurs
        Task {
            // Créer la course d'abord
            if let userId = authViewModel.currentUser?.id {
                await rideViewModel.requestRide(
                    pickup: rideRequest.pickupLocation,
                    dropoff: rideRequest.dropoffLocation,
                    userId: userId
                )
                
                // Si la course a été créée, démarrer la recherche
                if let ride = rideViewModel.currentRide {
                    driverSearchViewModel.ride = ride
                    driverSearchViewModel.rideId = ride.id
                    await driverSearchViewModel.searchDrivers(for: ride)
                }
            }
        }
    }
    
    private func stopSearch() {
        driverSearchViewModel.cancelSearch()
    }
    
    private func cancelRide() {
        // Arrêter immédiatement la recherche
        driverSearchViewModel.cancelSearch()
        
        Task {
            // Annuler la course via le ViewModel
            await rideViewModel.cancelRide()
            
            // Revenir à l'écran précédent (home) après l'annulation
            await MainActor.run {
                // Fermer cette vue et revenir à l'écran précédent
                dismiss()
            }
        }
    }
    
    private func loadRoute() {
        // Calculer la région de la carte pour centrer sur le trajet
        let centerLat = (rideRequest.pickupLocation.latitude + rideRequest.dropoffLocation.latitude) / 2
        let centerLon = (rideRequest.pickupLocation.longitude + rideRequest.dropoffLocation.longitude) / 2
        
        let latDelta = abs(rideRequest.pickupLocation.latitude - rideRequest.dropoffLocation.latitude) * 1.5
        let lonDelta = abs(rideRequest.pickupLocation.longitude - rideRequest.dropoffLocation.longitude) * 1.5
        
        mapViewModel.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
        
        // TODO: Charger la route depuis Google Directions API et l'afficher sur la carte
        // Task {
        //     do {
        //         let routeResult = try await GoogleDirectionsService.shared.calculateRoute(
        //             from: rideRequest.pickupLocation,
        //             to: rideRequest.dropoffLocation
        //         )
        //         // Afficher la route sur la carte
        //     } catch {
        //         print("Erreur lors du chargement de la route: \(error.localizedDescription)")
        //     }
        // }
    }
    
}

#Preview {
    SearchingDriversView(
        rideRequest: RideRequest(
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Commune de Ngaliema"),
            dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Green Olive"),
            selectedVehicle: .economy,
            estimatedPrice: 18000,
            estimatedDistance: 10.1,
            estimatedTime: 42
        )
    )
    .environmentObject(AuthViewModel())
}
