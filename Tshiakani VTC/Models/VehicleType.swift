//
//  VehicleType.swift
//  Tshiakani VTC
//
//  Modèle pour les types de véhicules (Economy, Comfort, Business)
//

import Foundation

enum VehicleType: String, Codable, CaseIterable, Identifiable, Hashable {
    case economy = "economy"
    case comfort = "comfort"
    case business = "business"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .economy: return "Economy"
        case .comfort: return "Comfort"
        case .business: return "Business"
        }
    }
    
    var icon: String {
        switch self {
        case .economy: return "car.fill"
        case .comfort: return "car.2.fill"
        case .business: return "car.side.fill"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .economy: return 1.0
        case .comfort: return 1.3
        case .business: return 1.6
        }
    }
    
    var description: String {
        switch self {
        case .economy: return "Véhicule économique"
        case .comfort: return "Véhicule confortable"
        case .business: return "Véhicule de luxe"
        }
    }
}

struct VehicleOption: Identifiable {
    let id = UUID()
    let type: VehicleType
    let price: Double
    let originalPrice: Double? // Prix barré si réduction
    let estimatedWaitTime: Int // Temps d'attente en minutes
    var isSelected: Bool
}

