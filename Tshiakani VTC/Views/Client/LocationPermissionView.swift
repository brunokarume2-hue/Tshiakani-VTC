//
//  LocationPermissionView.swift
//  Tshiakani VTC
//
//  Vue native pour gérer les permissions de localisation
//  Affiche conditionnellement la carte ou un écran explicatif
//

import SwiftUI
import MapKit

struct LocationPermissionView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa par défaut
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var hasRequestedInitialAuth = false
    
    var body: some View {
        Group {
            if locationManager.isAuthorized {
                // Afficher la carte si autorisé
                mapView
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                // Afficher l'écran explicatif si refusé
                deniedView
            } else {
                // En attente de la décision (notDetermined)
                // La carte s'affichera une fois l'autorisation accordée
                mapView
                    .onAppear {
                        // Demander l'autorisation au premier affichage (une seule fois)
                        if !hasRequestedInitialAuth {
                            hasRequestedInitialAuth = true
                            // Petit délai pour que la vue soit complètement chargée
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                locationManager.requestAuthorization()
                            }
                        }
                    }
            }
        }
        .onChange(of: locationManager.userLocation?.latitude) { _, _ in
            if let location = locationManager.userLocation, locationManager.shouldAnimateToLocation {
                withAnimation(.easeInOut(duration: 0.8)) {
                    mapRegion.center = location
                    mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                }
            }
        }
        .onChange(of: locationManager.shouldAnimateToLocation) { _, shouldAnimate in
            if shouldAnimate, let location = locationManager.userLocation {
                withAnimation(.easeInOut(duration: 0.8)) {
                    mapRegion.center = location
                    mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                }
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map {
            if locationManager.isAuthorized {
                UserAnnotation()
            }
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in
            mapRegion = MKCoordinateRegion(
                center: context.region.center,
                span: context.region.span
            )
        }
        .ignoresSafeArea()
            .onAppear {
                // Centrer sur la position de l'utilisateur si disponible
                if let location = locationManager.userLocation {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        mapRegion.center = location
                        mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Bouton pour recentrer sur la position avec animation
                if locationManager.isAuthorized {
                    Button(action: {
                        locationManager.centerOnUserLocation { coordinate in
                            if let coordinate = coordinate {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    mapRegion.center = coordinate
                                    mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                }
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            .scaleEffect(locationManager.shouldAnimateToLocation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: locationManager.shouldAnimateToLocation)
                    }
                    .padding()
                }
            }
            .overlay(alignment: .top) {
                // Afficher les erreurs de localisation
                if let error = locationManager.locationError, error != .denied {
                    LocationErrorView(error: error) {
                        locationManager.startUpdatingLocation()
                    }
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
    }
    
    // MARK: - Denied View
    
    private var deniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icône
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
            
            // Titre et description
            VStack(spacing: 12) {
                Text("Localisation désactivée")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Pour utiliser Tshiakani VTC, nous avons besoin de votre position pour vous connecter avec les conducteurs disponibles.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Bouton pour ouvrir les paramètres
            Button(action: {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Activer dans les réglages")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            
            // Message d'information
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Votre position n'est jamais partagée sans votre consentement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color.white)
    }
}

#Preview {
    LocationPermissionView(locationManager: LocationManager.shared)
}

