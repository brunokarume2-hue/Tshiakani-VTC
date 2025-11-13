//
//  PaymentMethod+Extensions.swift
//  Tshiakani VTC
//
//  Extensions pour PaymentMethod
//

import Foundation
import SwiftUI

// MARK: - PaymentMethod Extensions
// Note: PaymentMethod est défini dans Models/Ride.swift

extension PaymentMethod {
    /// Nom d'affichage localisé de la méthode de paiement
    var displayName: String {
        switch self {
        case .cash:
            return "Espèces"
        case .stripe:
            return "Carte bancaire"
        case .mpesa:
            return "M-Pesa"
        case .orangeMoney:
            return "Orange Money"
        case .airtelMoney:
            return "Airtel Money"
        case .paypal:
            return "PayPal"
        }
    }
    
    /// Icône SF Symbol pour la méthode de paiement
    var icon: String {
        switch self {
        case .cash:
            return "banknote.fill"
        case .stripe:
            return "creditcard.fill"
        case .mpesa:
            return "phone.fill"
        case .orangeMoney:
            return "phone.fill"
        case .airtelMoney:
            return "phone.fill"
        case .paypal:
            return "creditcard.fill"
        }
    }
    
    /// Couleur spécifique pour chaque méthode de paiement
    var color: Color {
        switch self {
        case .cash:
            return Color.gray
        case .stripe:
            return Color.blue
        case .mpesa:
            return Color(red: 0.0, green: 0.6, blue: 0.3) // Vert M-Pesa
        case .orangeMoney:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Orange Orange Money
        case .airtelMoney:
            return Color(red: 1.0, green: 0.2, blue: 0.0) // Rouge Airtel
        case .paypal:
            return Color.blue
        }
    }
    
    /// Méthodes de paiement disponibles pour l'utilisateur
    static var availableMethods: [PaymentMethod] {
        [.cash, .stripe, .mpesa, .orangeMoney]
    }
    
    /// Vérifie si cette méthode nécessite un menu contextuel (pour intégration API future)
    var requiresContextMenu: Bool {
        switch self {
        case .orangeMoney, .mpesa:
            return true
        default:
            return false
        }
    }
}

