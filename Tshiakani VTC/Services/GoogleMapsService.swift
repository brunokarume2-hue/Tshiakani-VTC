//
//  GoogleMapsService.swift
//  Tshiakani VTC
//
//  Service pour initialiser et gérer Google Maps SDK
//

import Foundation

#if canImport(GoogleMaps)
import GoogleMaps
#endif

class GoogleMapsService {
    static let shared = GoogleMapsService()
    
    private var isInitialized = false
    private var apiKey: String?
    private let initializationLock = NSLock()
    
    private init() {}
    
    /// Stocke la clé API pour initialisation lazy (performance)
    func setAPIKey(_ key: String) {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        self.apiKey = key
    }
    
    /// Récupère la clé API stockée
    func getAPIKey() -> String? {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        return apiKey
    }
    
    /// Initialise le SDK Google Maps avec la clé API
    /// À appeler dans TshiakaniVTCApp.init() ou AppDelegate
    /// IMPORTANT: Doit être appelé de manière synchrone sur le thread principal
    func initialize(apiKey: String) {
        #if canImport(GoogleMaps)
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        // Vérifier si déjà initialisé
        if isInitialized {
            print("⚠️ Google Maps SDK déjà initialisé - Ignoré")
            return
        }
        
        // Vérifier que la clé API n'est pas vide
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            print("❌ ERREUR: Clé API Google Maps invalide ou vide")
            return
        }
        
        // IMPORTANT: GMSServices.provideAPIKey DOIT être appelé de manière synchrone
        // et sur le thread principal AVANT toute création de GMSMapView
        if Thread.isMainThread {
            // Initialiser directement si on est sur le main thread
            GMSServices.provideAPIKey(apiKey)
            isInitialized = true
            print("✅ Google Maps SDK initialisé avec succès (main thread synchrone)")
            print("✅ Clé API: \(String(apiKey.prefix(10)))...")
            print("✅ SDK prêt à être utilisé")
        } else {
            // Si on n'est pas sur le main thread, utiliser sync pour garantir l'initialisation
            DispatchQueue.main.sync {
                GMSServices.provideAPIKey(apiKey)
                self.isInitialized = true
                print("✅ Google Maps SDK initialisé avec succès (sync main thread)")
                print("✅ Clé API: \(String(apiKey.prefix(10)))...")
                print("✅ SDK prêt à être utilisé")
            }
        }
        #else
        print("❌ ERREUR: Google Maps SDK non disponible")
        print("⚠️ Les packages sont peut-être installés mais pas correctement liés au target.")
        print("📋 Instructions:")
        print("   1. Vérifiez dans Xcode : Target > General > Frameworks, Libraries, and Embedded Content")
        print("   2. Assurez-vous que GoogleMaps.xcframework et GooglePlaces.xcframework sont présents")
        print("   3. Installez le package : https://github.com/googlemaps/ios-maps-sdk")
        #endif
    }
    
    /// Marque le SDK comme initialisé (utilisé lorsque l'initialisation est faite directement)
    func markAsInitialized() {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        isInitialized = true
    }
    
    /// Vérifie si le SDK est initialisé
    var initialized: Bool {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        return isInitialized
    }
}

