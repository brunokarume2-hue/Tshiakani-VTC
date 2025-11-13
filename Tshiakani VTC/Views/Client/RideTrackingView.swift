//
//  RideTrackingView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

#if canImport(UIKit)
import UIKit
#endif

struct RideTrackingView: View {
    let ride: Ride
    @EnvironmentObject var rideViewModel: RideViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var estimatedArrival = Date().addingTimeInterval(15 * 60) // 15 minutes
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var navigateToSummary = false
    
    // Couleurs et constantes simplifiées
    private let orangeColor = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    var body: some View {
        ZStack {
            mapView
            arrivalTimeOverlay
            bottomPanel
        }
        .navigationBarTitleDisplayMode(.inline)
        // OPTIMISATION: Utiliser le bouton retour par défaut de NavigationStack
        // Pas besoin de bouton personnalisé car la navigation est gérée automatiquement
        .navigationDestination(isPresented: $navigateToSummary) {
            // Utiliser le Ride depuis RideViewModel si disponible, sinon utiliser celui passé en paramètre
            RideSummaryScreen(ride: rideViewModel.currentRide ?? ride)
                .environmentObject(authViewModel)
                .environmentObject(rideViewModel)
        }
        .onAppear {
            updateRegion()
            // Charger les détails de la course depuis le backend
            Task {
                await rideViewModel.loadRideDetails(rideId: ride.id)
            }
        }
        .onChange(of: ride.status) { _, newStatus in
            checkIfCompleted(status: newStatus)
        }
        .onChange(of: rideViewModel.currentRide?.status) { _, newStatus in
            if let newStatus = newStatus {
                checkIfCompleted(status: newStatus)
                // Si la course est terminée, naviguer vers le résumé
                if newStatus == .completed {
                    navigateToSummary = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            // Point de prise en charge
            Annotation("Pickup", coordinate: ride.pickupLocation.coordinate) {
                pickupMarker
            }
            
            // Destination
            Annotation("Destination", coordinate: ride.dropoffLocation.coordinate) {
                destinationMarker
            }
            
            // Position du conducteur
            if let driverLocation = ride.driverLocation {
                Annotation("Driver", coordinate: driverLocation.coordinate) {
                    driverMarker
                }
            }
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
    }
    
    private var pickupMarker: some View {
        ZStack {
            Circle()
                .fill(orangeColor)
                .frame(width: 20, height: 20)
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
        }
    }
    
    private var destinationMarker: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 40))
            .foregroundColor(orangeColor)
    }
    
    private var driverMarker: some View {
        Image(systemName: "car.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .padding(6)
            .background(Color.black)
            .clipShape(Circle())
            .shadow(radius: 5)
    }
    
    private var arrivalTimeOverlay: some View {
        VStack {
            HStack {
                Spacer()
                arrivalTimePill
                Spacer()
            }
            .padding(.top, 20)
            Spacer()
        }
    }
    
    private var arrivalTimePill: some View {
        HStack(spacing: AppDesign.spacingS) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.accentOrange)
            
            Text("Arrivée dans:")
                .font(AppTypography.subheadline(weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Text("\(max(0, Int(estimatedArrival.timeIntervalSinceNow / 60))) min")
                .font(AppTypography.headline(weight: .bold))
                .foregroundColor(AppColors.accentOrange)
                .monospacedDigit()
        }
        .padding(.horizontal, AppDesign.spacingL)
        .padding(.vertical, AppDesign.spacingM)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 25)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
    
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            panelContent
        }
    }
    
    private var panelContent: some View {
        VStack(spacing: 0) {
            dragIndicator
            driverInfoSection
        }
        .background(.regularMaterial)
        .cornerRadius(AppDesign.cornerRadiusXL)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
    }
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppColors.secondaryText.opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.top, AppDesign.spacingS)
    }
    
    private var driverInfoSection: some View {
        VStack(spacing: AppDesign.spacingM) {
            driverInfo
            callButton
        }
        .padding(AppDesign.spacingM)
    }
    
    private var driverInfo: some View {
        HStack(spacing: AppDesign.spacingM) {
            // Avatar du chauffeur avec gradient (design moderne inspiré de l'image)
            ZStack {
                // Cercle de fond avec effet de profondeur
                Circle()
                    .fill(AppColors.accentOrange.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .blur(radius: 10)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(ride.driverId?.prefix(1).uppercased() ?? "D")
                            .font(AppTypography.title2(weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            
            VStack(alignment: .leading, spacing: AppDesign.spacingXS) {
                Text("Votre chauffeur arrive")
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                HStack(spacing: AppDesign.spacingXS) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accentOrange)
                    
                    Text("En route")
                        .font(AppTypography.subheadline(weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                    
                    Text("•")
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.horizontal, 4)
                    
                    Text("\(max(0, Int(estimatedArrival.timeIntervalSinceNow / 60))) min")
                        .font(AppTypography.subheadline(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                        .monospacedDigit()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AppDesign.spacingS)
    }
    
    private var callButton: some View {
        Button(action: {
            HapticFeedback.medium()
            callDriver()
        }) {
            HStack(spacing: AppDesign.spacingM) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Appeler le chauffeur")
                    .font(AppTypography.headline(weight: .semibold))
            }
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
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(EnhancedButtonStyle())
        .accessibilityLabel("Appeler le chauffeur")
        .accessibilityHint("Appeler le chauffeur par téléphone")
    }
    
    // MARK: - Helper Methods
    
    private func checkIfCompleted(status: RideStatus) {
        if status == RideStatus.completed {
            navigateToSummary = true
        }
    }
    
    private func callDriver() {
        // Récupérer le numéro de téléphone du chauffeur
        // Pour le moment, utiliser une valeur par défaut ou récupérer depuis l'API
        // TODO: Récupérer le numéro réel du chauffeur depuis l'API
        if let driverId = ride.driverId {
            Task {
                do {
                    let driver = try await APIService.shared.getUser(id: driverId)
                    let phoneNumber = driver.phoneNumber
                    
                    let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: "+", with: "")
                    
                    if let phoneURL = URL(string: "tel://\(cleanPhone)") {
                        await MainActor.run {
                            #if os(iOS)
                            if UIApplication.shared.canOpenURL(phoneURL) {
                                UIApplication.shared.open(phoneURL)
                            }
                            #endif
                        }
                    }
                } catch {
                    print("Erreur lors de la récupération du numéro du chauffeur: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateEstimatedArrival() {
        // Mettre à jour le temps d'arrivée estimé
        // TODO: Utiliser la position réelle du conducteur pour calculer l'ETA
        estimatedArrival = Date().addingTimeInterval(6 * 60) // 6 minutes par défaut
    }
    
    private func updateRegion() {
        let center = CLLocationCoordinate2D(
            latitude: ride.dropoffLocation.latitude,
            longitude: ride.dropoffLocation.longitude
        )
        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}


#Preview {
    RideTrackingView(ride: Ride(
        clientId: "test",
        pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Point A"),
        dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Point B"),
        estimatedPrice: 1500
    ))
}
