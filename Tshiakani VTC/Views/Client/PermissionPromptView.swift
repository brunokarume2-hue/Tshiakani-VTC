//
//  PermissionPromptView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import CoreLocation

struct PermissionPromptView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icône de localisation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            // Titre et description
            VStack(spacing: 12) {
                Text("Autoriser la localisation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Tshiakani VTC a besoin de votre position pour vous proposer les meilleurs trajets et vous connecter rapidement avec les conducteurs disponibles.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Options d'autorisation
            VStack(spacing: 12) {
                if locationManager.authorizationStatus == .notDetermined {
                    Button(action: {
                        // Demander l'autorisation - cela déclenchera la popup système iOS
                        locationManager.requestAuthorization()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Autoriser lorsque l'app est active")
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
                    }
                }
                
                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    Button(action: {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Ouvrir les paramètres")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            
            // Informations supplémentaires
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Votre position n'est jamais partagée sans votre consentement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .onChange(of: locationManager.authorizationStatus) { oldStatus, newStatus in
            // Fermer automatiquement la vue quand l'autorisation est accordée
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Démarrer la mise à jour de la localisation
                locationManager.startUpdatingLocation()
                // Fermer la vue après un court délai pour laisser le temps à l'animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    PermissionPromptView(locationManager: LocationManager.shared)
}

