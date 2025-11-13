//
//  RideConfirmationView.swift
//  Tshiakani VTC
//
//  Écran de confirmation de commande (Image 1)
//  S'affiche quand le client a choisi l'adresse de destination
//

import SwiftUI
import MapKit

struct RideConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Modèle simplifié pour toutes les données
    @State private var rideRequest: RideRequest
    
    @State private var region: MKCoordinateRegion
    @State private var routePolyline: String?
    @State private var navigateToSearch = false
    
    // Prix des différents types de véhicules
    @State private var vehiclePrices: [VehicleType: (min: Int, max: Int)] = [:]
    
    init(pickupLocation: Location, dropoffLocation: Location, estimatedPrice: Double, estimatedDistance: Double, estimatedTime: Int = 42) {
        // Créer le modèle simplifié
        _rideRequest = State(initialValue: RideRequest(
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            selectedVehicle: .economy,
            estimatedPrice: estimatedPrice,
            estimatedDistance: estimatedDistance,
            estimatedTime: estimatedTime
        ))
        
        // Calculer la région pour centrer la carte sur l'itinéraire
        let centerLat = (pickupLocation.latitude + dropoffLocation.latitude) / 2
        let centerLon = (pickupLocation.longitude + dropoffLocation.longitude) / 2
        
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
            // Carte Google Maps en arrière-plan
            GoogleMapView(
                region: $region,
                pickupLocation: rideRequest.pickupLocation,
                dropoffLocation: rideRequest.dropoffLocation,
                showsUserLocation: true,
                driverAnnotations: [],
                availableDrivers: [],
                driverLocation: nil,
                routePolyline: routePolyline,
                onLocationUpdate: nil,
                onRegionChange: { newRegion in
                    region = newRegion
                }
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Bouton de retour en haut à gauche
                HStack {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.thinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    .padding(.leading, AppDesign.spacingM)
                    .padding(.top, AppDesign.spacingM)
                    .accessibilityLabel("Retour")
                    .accessibilityHint("Retourner à l'écran précédent")
                    
                    Spacer()
                }
                
                Spacer()
                
                // Panneau de confirmation en bas (style Image 1)
                VStack(spacing: 0) {
                    // Indicateur de drag
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.secondaryText.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, AppDesign.spacingS)
                    
                    // Contenu du panneau simplifié
                    VStack(spacing: AppDesign.spacingM) {
                        // Point de départ et destination (affichage uniquement)
                        VStack(spacing: AppDesign.spacingS) {
                            // Point de départ
                            HStack(spacing: AppDesign.spacingS) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppColors.error)
                                
                                Text(rideRequest.pickupLocation.address ?? "Point de départ")
                                    .font(AppTypography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            
                            // Ligne de connexion
                            Rectangle()
                                .fill(AppColors.secondaryText.opacity(0.3))
                                .frame(width: 2, height: 20)
                                .padding(.leading, 3)
                            
                            // Destination
                            HStack(spacing: AppDesign.spacingS) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.accentOrange)
                                
                                Text(rideRequest.dropoffLocation.address ?? "Destination")
                                    .font(AppTypography.body(weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(rideRequest.estimatedTime) min")
                                    .font(AppTypography.caption())
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.vertical, AppDesign.spacingS)
                        .background(.thinMaterial)
                        .cornerRadius(AppDesign.cornerRadiusM)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        Divider()
                            .padding(.horizontal, AppDesign.spacingM)
                        
                        // Sélection de véhicule horizontale (simplifiée)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppDesign.spacingM) {
                                ForEach([VehicleType.economy, .comfort, .business], id: \.self) { vehicleType in
                                    VehicleTypeCard(
                                        type: vehicleType,
                                        priceRange: vehiclePrices[vehicleType] ?? calculatePriceRange(for: vehicleType),
                                        estimatedTime: vehicleType == .economy ? 9 : vehicleType == .comfort ? 12 : 9,
                                        isSelected: rideRequest.selectedVehicle == vehicleType,
                                        isFastest: vehicleType == .business
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            rideRequest.selectedVehicle = vehicleType
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppDesign.spacingM)
                        }
                        .padding(.vertical, AppDesign.spacingS)
                        
                        // Bouton Commander avec gradient
                        Button(action: {
                            HapticFeedback.medium()
                            withAnimation(AppDesign.animationSnappy) {
                                navigateToSearch = true
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
                        .buttonShadow()
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.bottom, AppDesign.spacingM)
                        .accessibilityLabel("Commander")
                        .accessibilityHint("Confirmer la commande et rechercher un chauffeur")
                    }
                    .padding(.top, AppDesign.spacingM)
                }
                .background(.regularMaterial)
                .cornerRadius(AppDesign.cornerRadiusXL, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                .frame(maxHeight: 350)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AppDesign.animationSmooth, value: navigateToSearch)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToSearch) {
            // Navigation simplifiée avec le modèle RideRequest
            SearchingDriversView(rideRequest: rideRequest)
                .environmentObject(authViewModel)
        }
        .onAppear {
            calculateVehiclePrices()
            loadRoute()
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateVehiclePrices() {
        let ecoPrice = Int(rideRequest.estimatedPrice)
        let comfortPrice = Int(rideRequest.estimatedPrice * VehicleType.comfort.multiplier)
        let businessPrice = Int(rideRequest.estimatedPrice * VehicleType.business.multiplier)
        
        vehiclePrices = [
            .economy: (ecoPrice - 1750, ecoPrice + 2050), // 16200-19750
            .comfort: (comfortPrice, comfortPrice),
            .business: (businessPrice, businessPrice)
        ]
    }
    
    private func calculatePriceRange(for type: VehicleType) -> (min: Int, max: Int) {
        let price = Int(rideRequest.estimatedPrice * type.multiplier)
        switch type {
        case .economy:
            return (price - 1750, price + 2050)
        case .comfort, .business:
            return (price, price)
        }
    }
    
    private func loadRoute() {
        print("🗺️ RideConfirmationView: Chargement de la route...")
        print("📍 Point de départ: \(rideRequest.pickupLocation.latitude), \(rideRequest.pickupLocation.longitude)")
        print("📍 Destination: \(rideRequest.dropoffLocation.latitude), \(rideRequest.dropoffLocation.longitude)")
        
        Task {
            do {
                let routeResult = try await GoogleDirectionsService.shared.calculateRoute(
                    from: rideRequest.pickupLocation,
                    to: rideRequest.dropoffLocation
                )
                await MainActor.run {
                    routePolyline = routeResult.polyline
                    print("✅ Route chargée avec succès")
                    print("📍 Polyline: \(routeResult.polyline.prefix(50))...")
                    print("📍 Distance: \(routeResult.distance) km")
                    print("📍 Durée: \(routeResult.duration) min")
                    
                    // Mettre à jour la région pour centrer sur la route
                    updateRegionForRoute()
                }
            } catch {
                print("❌ Erreur lors du chargement de la route: \(error.localizedDescription)")
                // En cas d'erreur, continuer sans route
            }
        }
    }
    
    private func updateRegionForRoute() {
        // Ajuster la région pour afficher toute la route
        let centerLat = (rideRequest.pickupLocation.latitude + rideRequest.dropoffLocation.latitude) / 2
        let centerLon = (rideRequest.pickupLocation.longitude + rideRequest.dropoffLocation.longitude) / 2
        
        let latDelta = abs(rideRequest.pickupLocation.latitude - rideRequest.dropoffLocation.latitude) * 1.8
        let lonDelta = abs(rideRequest.pickupLocation.longitude - rideRequest.dropoffLocation.longitude) * 1.8
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
    }
}

// MARK: - Vehicle Type Card (horizontale)

struct VehicleTypeCard: View {
    let type: VehicleType
    let priceRange: (min: Int, max: Int)
    let estimatedTime: Int
    let isSelected: Bool
    let isFastest: Bool
    let onSelect: () -> Void
    
    init(type: VehicleType, priceRange: (min: Int, max: Int), estimatedTime: Int, isSelected: Bool, isFastest: Bool = false, onSelect: @escaping () -> Void) {
        self.type = type
        self.priceRange = priceRange
        self.estimatedTime = estimatedTime
        self.isSelected = isSelected
        self.isFastest = isFastest
        self.onSelect = onSelect
    }
    
    var displayName: String {
        if isFastest {
            return "Le plus rapide"
        }
        return type.displayName
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(AppDesign.animationSnappy) {
                onSelect()
            }
        }) {
            VStack(spacing: AppDesign.spacingS) {
                // Icône de véhicule avec gradient
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [AppColors.accentOrange.opacity(0.2), AppColors.accentOrange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [AppColors.secondaryBackground.opacity(0.5), AppColors.secondaryBackground.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 60)
                    
                    VStack(spacing: 4) {
                        // Temps estimé
                        Text("\(estimatedTime) min.")
                            .font(AppTypography.caption2(weight: .medium))
                            .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                        
                        // Icône de véhicule
                        if type == .business && isFastest {
                            // Deux voitures pour "Le plus rapide"
                            HStack(spacing: -8) {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                                Image(systemName: "car.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                            }
                        } else {
                            Image(systemName: type.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                        }
                    }
                }
                .shadow(color: isSelected ? AppColors.accentOrange.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
                
                // Nom du type
                Text(displayName)
                    .font(AppTypography.caption(weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                
                // Prix
                if priceRange.min == priceRange.max {
                    Text("\(priceRange.min) FC")
                        .font(AppTypography.caption2(weight: .bold))
                        .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                } else {
                    Text("\(priceRange.min)-\(priceRange.max) FC")
                        .font(AppTypography.caption2(weight: .bold))
                        .foregroundColor(isSelected ? AppColors.accentOrange : AppColors.secondaryText)
                }
            }
            .frame(width: 100)
            .padding(.vertical, AppDesign.spacingM)
            .padding(.horizontal, AppDesign.spacingS)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [AppColors.accentOrange.opacity(0.1), AppColors.accentOrange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.thinMaterial) :
                LinearGradient(
                    colors: [Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.thinMaterial)
            )
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(isSelected ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? .black.opacity(0.1) : .black.opacity(0.05), radius: isSelected ? 6 : 2, x: 0, y: isSelected ? 3 : 1)
        }
        .buttonStyle(EnhancedButtonStyle())
        .animation(AppDesign.animationSnappy, value: isSelected)
        .accessibilityLabel(displayName)
        .accessibilityHint(isSelected ? "Sélectionné" : "Sélectionner ce type de véhicule")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    RideConfirmationView(
        pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Commune de Ngaliema"),
        dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Green Olive"),
        estimatedPrice: 18000,
        estimatedDistance: 10.1,
        estimatedTime: 42
    )
    .environmentObject(AuthViewModel())
}

