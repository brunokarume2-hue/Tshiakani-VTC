//
//  DriverFoundView.swift
//  Tshiakani VTC
//
//  Écran d'attente lorsque le chauffeur est trouvé
//  S'affiche après qu'un chauffeur ait accepté la course
//

import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct DriverFoundView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var rideViewModel = RideViewModel()
    
    let rideRequest: RideRequest
    let driver: User
    let ride: Ride
    
    @State private var region: MKCoordinateRegion
    @State private var driverLocation: Location?
    @State private var routePolyline: String?
    @State private var estimatedArrivalMinutes: Int = 5
    @State private var navigateToTracking = false
    
    init(rideRequest: RideRequest, driver: User, ride: Ride) {
        self.rideRequest = rideRequest
        self.driver = driver
        self.ride = ride
        
        // Calculer la région pour centrer la carte
        let centerLat = (rideRequest.pickupLocation.latitude + rideRequest.dropoffLocation.latitude) / 2
        let centerLon = (rideRequest.pickupLocation.longitude + rideRequest.dropoffLocation.longitude) / 2
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        ))
    }
    
    var body: some View {
        ZStack {
            // Carte Google Maps en arrière-plan
            GoogleMapView(
                region: $region,
                pickupLocation: rideRequest.pickupLocation,
                dropoffLocation: rideRequest.dropoffLocation,
                showsUserLocation: true,
                driverAnnotations: [],
                availableDrivers: [driver],
                driverLocation: driverLocation,
                routePolyline: routePolyline,
                onLocationUpdate: nil,
                onRegionChange: { newRegion in
                    region = newRegion
                }
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Badge "Arrivée dans X min" en haut (style Bolt)
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.accentOrange)
                        
                        Text("Arrivée dans")
                            .font(AppTypography.subheadline(weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(estimatedArrivalMinutes) min")
                            .font(AppTypography.headline(weight: .bold))
                            .foregroundColor(AppColors.accentOrange)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Panneau d'information en bas (style Bolt)
                VStack(spacing: 0) {
                    // Indicateur de drag
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.secondaryText.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, AppDesign.spacingS)
                    
                    // Contenu du panneau minimaliste (style Bolt)
                    VStack(spacing: 20) {
                        // Informations du chauffeur
                        HStack(spacing: 16) {
                            // Avatar du chauffeur (cercle avec gradient)
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                Text(driver.name.prefix(1).uppercased())
                                    .font(AppTypography.title2(weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Nom et note
                            VStack(alignment: .leading, spacing: 6) {
                                Text(driver.name)
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: 6) {
                                    if let rating = driver.driverInfo?.rating {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppColors.accentOrange)
                                        
                                        Text(String(format: "%.1f", rating))
                                            .font(AppTypography.subheadline(weight: .semibold))
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    
                                    Text("•")
                                        .foregroundColor(AppColors.secondaryText)
                                        .padding(.horizontal, 4)
                                    
                                    Text("En route")
                                        .font(AppTypography.subheadline(weight: .medium))
                                        .foregroundColor(AppColors.accentOrange)
                                }
                            }
                            
                            Spacer()
                            
                            // Bouton Appeler (flottant)
                            Button(action: {
                                HapticFeedback.medium()
                                callDriver()
                            }) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: AppColors.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Bouton Suivre la course (pleine largeur)
                        Button(action: {
                            HapticFeedback.medium()
                            navigateToTracking = true
                        }) {
                            Text("Suivre la course")
                                .font(AppTypography.headline(weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(AppDesign.cornerRadiusL)
                                .shadow(color: AppColors.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 12)
                }
                .background(.regularMaterial)
                .cornerRadius(AppDesign.cornerRadiusXL, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                .frame(maxHeight: 250)
            }
        }
        .toolbar(.hidden) // Toolbar cachée car le panneau contient toutes les actions
        .navigationDestination(isPresented: $navigateToTracking) {
            RideTrackingView(ride: ride)
                .environmentObject(rideViewModel)
        }
        .onAppear {
            startTrackingDriver()
            loadRoute()
        }
        .onDisappear {
            stopTrackingDriver()
        }
        .onChange(of: rideViewModel.currentRide) { oldValue, newRide in
            if let newRide = newRide, newRide.status == .driverArriving || newRide.status == .inProgress {
                // Mettre à jour l'ETA
                updateEstimatedArrival()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startTrackingDriver() {
        Task {
            await fetchDriverLocation()
        }
    }
    
    private func stopTrackingDriver() {
        // Arrêter le suivi si nécessaire
    }
    
    private func fetchDriverLocation() async {
        do {
            let result = try await APIService.shared.trackDriver(rideId: ride.id)
            await MainActor.run {
                driverLocation = result.location
                estimatedArrivalMinutes = result.estimatedArrivalMinutes ?? 5
            }
        } catch {
            print("Erreur lors du suivi du chauffeur: \(error.localizedDescription)")
        }
    }
    
    private func loadRoute() {
        Task {
            do {
                let routeResult = try await GoogleDirectionsService.shared.calculateRoute(
                    from: rideRequest.pickupLocation,
                    to: rideRequest.dropoffLocation
                )
                await MainActor.run {
                    routePolyline = routeResult.polyline
                }
            } catch {
                print("Erreur lors du chargement de la route: \(error.localizedDescription)")
            }
        }
    }
    
    private func callDriver() {
        let phoneNumber = driver.phoneNumber
        
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let phoneURL = URL(string: "tel://\(cleanPhone)") {
            Task { @MainActor in
                #if os(iOS)
                if UIApplication.shared.canOpenURL(phoneURL) {
                    UIApplication.shared.open(phoneURL)
                }
                #endif
            }
        }
    }
    
    private func updateEstimatedArrival() {
        // Mettre à jour l'ETA basé sur la position du chauffeur
        Task {
            await fetchDriverLocation()
        }
    }
}

#Preview {
    DriverFoundView(
        rideRequest: RideRequest(
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Commune de Ngaliema"),
            dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Green Olive"),
            selectedVehicle: .economy,
            estimatedPrice: 18000,
            estimatedDistance: 10.1,
            estimatedTime: 42
        ),
        driver: User(
            id: "1",
            name: "Jean Kabongo",
            phoneNumber: "+243 900 000 000",
            email: nil,
            role: .driver,
            createdAt: Date(),
            isVerified: true,
            driverInfo: DriverInfo(
                isOnline: true,
                status: "available",
                rating: 4.8,
                totalRides: 150
            )
        ),
        ride: Ride(
            id: "1",
            clientId: "1",
            driverId: "1",
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Commune de Ngaliema"),
            dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Green Olive"),
            status: .accepted,
            estimatedPrice: 18000,
            isPaid: false,
            distance: 10.1,
            createdAt: Date()
        )
    )
    .environmentObject(AuthViewModel())
}

