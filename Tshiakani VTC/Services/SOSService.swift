//
//  SOSService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import Combine

class SOSService: ObservableObject {
    static let shared = SOSService()
    
    private let apiService = APIService.shared
    private let locationService = LocationService.shared
    
    private init() {}
    
    /// Signaler une urgence SOS
    func reportEmergency(rideId: String? = nil, message: String? = nil) async throws {
        guard let location = locationService.currentLocation else {
            throw NSError(domain: "SOSService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Position non disponible"])
        }
        
        let sosData: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "rideId": rideId as Any,
            "message": message ?? "Signalement d'urgence"
        ]
        
        // Envoyer au backend
        try await apiService.post(endpoint: "/sos", body: sosData)
    }
    
    /// Envoie une notification SOS
    func sendSOSNotification(location: Location, contact: String) async throws {
        // Envoyer une notification SMS ou email au contact d'urgence
        // Pour l'instant, on simule l'envoi
        print("🚨 SOS: Notification envoyée à \(contact) pour la localisation: \(location.address ?? "Position inconnue")")
    }
    
    /// Active l'alerte SOS
    func activateSOS(location: Location) async {
        do {
            try await reportEmergency(message: "Alerte SOS activée")
        } catch {
            print("❌ Erreur activateSOS: \(error)")
        }
    }
    
    /// Désactive l'alerte SOS
    func deactivateSOS() async {
        // TODO: Désactiver l'alerte SOS sur le backend
        print("🚨 SOS: Alerte désactivée")
    }
}

