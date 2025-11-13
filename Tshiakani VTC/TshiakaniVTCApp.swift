//
//  TshiakaniVTCApp.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
// TODO: Ajouter Firebase après installation du package
// import FirebaseCore

#if canImport(GoogleMaps)
import GoogleMaps
#endif

@main
struct TshiakaniVTCApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Initialiser Firebase (décommentez après installation du package)
        // FirebaseApp.configure()
        
        // OPTIMISATION: Ne plus initialiser Google Maps au démarrage
        // L'initialisation se fera de manière lazy quand ClientHomeView apparaît
        // Cela améliore significativement le temps de démarrage de l'app
        
        // Stocker la clé API pour initialisation lazy
        prepareGoogleMapsAPIKey()
        
        // Demander les permissions de notification au démarrage (non-bloquant)
        // Utiliser async pour ne pas bloquer le démarrage
        DispatchQueue.main.async {
            NotificationService.shared.requestAuthorization()
        }
    }
    
    private func prepareGoogleMapsAPIKey() {
        // Préparer la clé API sans initialiser le SDK (performance)
        var apiKey: String? = nil
        
        // Méthode 1: Depuis Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
           !key.isEmpty, key != "YOUR_API_KEY_HERE" {
            apiKey = key
        }
        
        // Méthode 2: Depuis les variables d'environnement
        if apiKey == nil {
            if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"],
               !key.isEmpty {
                apiKey = key
            }
        }
        
        // Méthode 3: Clé API de développement (fallback)
        if apiKey == nil {
            apiKey = "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"
        }
        
        // Stocker la clé API pour initialisation lazy
        if let key = apiKey, !key.isEmpty {
            GoogleMapsService.shared.setAPIKey(key)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
