//
//  ClientMainView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct ClientMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var rideViewModel = RideViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                // Si une course est en cours, afficher le suivi
                if let currentRide = rideViewModel.currentRide {
                    // Vue de suivi de course avec carte
                    RideTrackingView(ride: currentRide)
                        .environmentObject(authViewModel)
                        .environmentObject(rideViewModel)
                } else {
                    // Sinon, afficher la vue d'accueil (sans carte au début)
                    ClientHomeView()
                        .environmentObject(authViewModel)
                        .environmentObject(authManager)
                        .environmentObject(rideViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Demander l'autorisation de localisation au démarrage
            locationManager.requestAuthorizationIfNeeded()
        }
    }
}

#Preview {
    ClientMainView()
        .environmentObject(AuthViewModel())
        .environmentObject(AuthManager())
}
