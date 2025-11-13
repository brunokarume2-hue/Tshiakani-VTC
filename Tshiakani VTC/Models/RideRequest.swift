//
//  RideRequest.swift
//  Tshiakani VTC
//
//  Modèle de données pour simplifier le passage d'informations entre les écrans
//

import Foundation

/// Modèle simplifié pour les informations de commande
struct RideRequest: Identifiable {
    let id = UUID()
    var pickupLocation: Location
    var dropoffLocation: Location
    var selectedVehicle: VehicleType
    var estimatedPrice: Double
    var estimatedDistance: Double
    var estimatedTime: Int
    
    /// Calcule le prix final selon le type de véhicule
    var finalPrice: Double {
        estimatedPrice * selectedVehicle.multiplier
    }
}

