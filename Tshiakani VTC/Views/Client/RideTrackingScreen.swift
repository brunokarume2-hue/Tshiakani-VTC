//
//  RideTrackingScreen.swift
//  Tshiakani VTC
//
//  Écran de suivi de course en temps réel
//

import SwiftUI
import MapKit
import CoreLocation

struct RideTrackingScreen: View {
    // MARK: - State
    
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var alertManager = AlertManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var eta: Int = 5 // minutes
    @State private var isLoading = false
    @State private var showCancelConfirmation = false
    @State private var showShareSheet = false
    
    // MARK: - Driver Data (placeholder)
    
    private let driver = RideTrackingDriverInfo(
        id: "1",
        name: "Jean Kabila",
        phone: "+243 820098808",
        plateNumber: "KIN-123-AB",
        bikeType: "Moto 125cc",
        photoURL: nil,
        rating: 4.8,
        currentLocation: CLLocationCoordinate2D(latitude: -4.3280, longitude: 15.3140)
    )
    
    private let destination = CLLocationCoordinate2D(latitude: -4.3270, longitude: 15.3130)
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Carte principale
                mapView
                    .ignoresSafeArea(edges: .top)
                
                // Overlay UI
                VStack {
                    Spacer()
                    
                    // Carte d'informations
                    infoCard
                        .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Suivi de course")
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.accentOrange)
                    }
                }
            }
            .tshiakaniAlert()
            .sheet(isPresented: $showShareSheet) {
                RideTrackingShareSheet(activityItems: [shareText])
            }
            .confirmationDialog(
                "Annuler la course",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Annuler la course", role: .destructive) {
                    cancelRide()
                }
                Button("common.button.cancel".localized, role: .cancel) {}
            } message: {
                Text("Êtes-vous sûr de vouloir annuler cette course ?")
            }
            .onAppear {
                setupTracking()
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map {
            UserAnnotation()
            
            ForEach(mapAnnotations) { annotation in
                Annotation("", coordinate: annotation.coordinate) {
                    annotation.view
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
        .onChange(of: driver.currentLocation.latitude) { _, _ in
            updateMapRegion(to: driver.currentLocation)
        }
        .onChange(of: driver.currentLocation.longitude) { _, _ in
            updateMapRegion(to: driver.currentLocation)
        }
    }
    
    private var mapAnnotations: [RideTrackingMapAnnotationItem] {
        [
            RideTrackingMapAnnotationItem(
                coordinate: driver.currentLocation,
                view: AnyView(driverAnnotation)
            ),
            RideTrackingMapAnnotationItem(
                coordinate: destination,
                view: AnyView(destinationAnnotation)
            )
        ]
    }
    
    private var driverAnnotation: some View {
        VStack(spacing: 4) {
            Image(systemName: "motorcycle")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .padding(8)
                .background(AppColors.primaryBlue)
                .clipShape(Circle())
                .shadow(radius: 4)
            
            Text(driver.name.components(separatedBy: " ").first ?? "")
                .font(AppTypography.caption())
                .foregroundColor(AppColors.primaryText)
                .padding(4)
                .background(AppColors.background)
                .cornerRadius(6)
                .shadow(radius: 2)
        }
    }
    
    private var destinationAnnotation: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(AppColors.error)
                .shadow(radius: 4)
            
            Text("Destination")
                .font(AppTypography.caption())
                .foregroundColor(AppColors.primaryText)
                .padding(4)
                .background(AppColors.background)
                .cornerRadius(6)
                .shadow(radius: 2)
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(spacing: 20) {
            // ETA Section
            etaSection
            
            Divider()
            
            // Driver Info Section
            driverInfoSection
            
            Divider()
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - ETA Section
    
    private var etaSection: some View {
        VStack(spacing: 8) {
            if isLoading {
                TshiakaniLoader(message: "Mise à jour de la position...", size: .small)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(AppTypography.title3())
                        .foregroundColor(AppColors.accentOrange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arrive dans")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text("\(eta) minute\(eta > 1 ? "s" : "")")
                            .font(AppTypography.title2())
                            .foregroundColor(AppColors.primaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Driver Info Section
    
    private var driverInfoSection: some View {
        HStack(spacing: 16) {
            // Photo du conducteur
            AsyncImage(url: driver.photoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
            
            // Informations
            VStack(alignment: .leading, spacing: 6) {
                Text(driver.name)
                    .font(AppTypography.headline())
                    .foregroundColor(AppColors.primaryText)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                
                HStack(spacing: 8) {
                    Label(driver.plateNumber, systemImage: "number")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    Text("•")
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(driver.bikeType)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accentOrange)
                    
                    Text(String(format: "%.1f", driver.rating))
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Bouton principal : Appeler
            TshiakaniButton(
                title: "Appeler le conducteur",
                style: .primary,
                action: {
                    callDriver()
                },
                icon: "phone.fill"
            )
            
            // Boutons secondaires
            HStack(spacing: 12) {
                // Annuler
                TshiakaniButton(
                    title: "Annuler la course",
                    style: .danger,
                    action: {
                        showCancelConfirmation = true
                    }
                )
                
                // Partager
                TshiakaniButton(
                    title: "Partager",
                    style: .outline,
                    action: {
                        showShareSheet = true
                    },
                    icon: "square.and.arrow.up"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupTracking() {
        // Simuler la mise à jour de position
        startLocationUpdates()
    }
    
    private func startLocationUpdates() {
        isLoading = true
        
        // Simuler la réception de mises à jour de position
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            updateDriverLocation()
            
            // Simuler l'arrivée
            if self.eta <= 0 {
                timer.invalidate()
                self.rideCompleted()
            }
        }
    }
    
    private func updateDriverLocation() {
        // Simuler le mouvement du conducteur
        let randomLat = Double.random(in: -0.001...0.001)
        let randomLon = Double.random(in: -0.001...0.001)
        
        _ = CLLocationCoordinate2D(
            latitude: driver.currentLocation.latitude + randomLat,
            longitude: driver.currentLocation.longitude + randomLon
        )
        
        // Mettre à jour l'ETA (simulation)
        eta = max(0, eta - 1)
        isLoading = false
    }
    
    private func updateMapRegion(to location: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            region.center = location
        }
    }
    
    private func callDriver() {
        // Masquer le numéro pour l'affichage
        let maskedPhone = driver.phone.maskedPhoneNumber()
        
        // Ouvrir l'appel téléphonique
        if let phoneURL = URL(string: "tel://\(driver.phone.replacingOccurrences(of: " ", with: ""))") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
            } else {
                alertManager.showError(
                    title: "Erreur",
                    message: "Impossible de passer l'appel. Numéro: \(maskedPhone)"
                )
            }
        }
    }
    
    private func cancelRide() {
        isLoading = true
        
        // Simuler l'annulation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            alertManager.showSuccess(
                title: "Course annulée",
                message: "Votre course a été annulée avec succès."
            ) {
                dismiss()
            }
        }
    }
    
    private func rideCompleted() {
        alertManager.showSuccess(
            title: "Course terminée",
            message: "Votre conducteur est arrivé !"
        ) {
            dismiss()
        }
    }
    
    private var shareText: String {
        "Je suis en cours avec \(driver.name) sur Tshiakani VTC. Arrivée prévue dans \(eta) minute\(eta > 1 ? "s" : "")."
    }
}

// MARK: - Supporting Types

struct RideTrackingDriverInfo {
    let id: String
    let name: String
    let phone: String
    let plateNumber: String
    let bikeType: String
    let photoURL: URL?
    let rating: Double
    var currentLocation: CLLocationCoordinate2D
}

struct RideTrackingMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let view: AnyView
}

// MARK: - Share Sheet

struct RideTrackingShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    RideTrackingScreen()
}

