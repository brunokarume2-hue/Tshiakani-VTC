//
//  LocationErrorView.swift
//  Tshiakani VTC
//
//  Vue pour afficher les erreurs de localisation
//

import SwiftUI

struct LocationErrorView: View {
    let error: LocationError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: errorIcon)
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(errorTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(errorDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if error == .inaccurate || error == .networkError {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Réessayer")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var errorIcon: String {
        switch error {
        case .denied, .servicesDisabled:
            return "location.slash.fill"
        case .inaccurate:
            return "location.circle"
        case .networkError:
            return "wifi.slash"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .denied:
            return "Localisation refusée"
        case .servicesDisabled:
            return "Services désactivés"
        case .inaccurate:
            return "Localisation imprécise"
        case .networkError:
            return "Erreur réseau"
        case .unknown:
            return "Erreur de localisation"
        }
    }
    
    private var errorDescription: String {
        switch error {
        case .denied:
            return "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
        case .servicesDisabled:
            return "Les services de localisation sont désactivés sur cet appareil."
        case .inaccurate:
            return "La localisation est imprécise. Veuillez réessayer."
        case .networkError:
            return "Erreur de connexion réseau. Vérifiez votre connexion internet."
        case .unknown:
            return "Une erreur inconnue s'est produite."
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LocationErrorView(error: .denied) {}
        LocationErrorView(error: .inaccurate) {}
        LocationErrorView(error: .networkError) {}
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

