//
//  FeatureFlags.swift
//  Tshiakani VTC
//
//  Configuration des fonctionnalités pour le lancement à Kinshasa
//  Permet d'activer/désactiver facilement les fonctionnalités non essentielles
//

import Foundation

/// Configuration des fonctionnalités de l'application
/// Permet d'activer/désactiver les fonctionnalités pour optimiser le lancement
struct FeatureFlags {
    
    // MARK: - Fonctionnalités Principales (Toujours actives)
    
    /// Authentification et gestion de compte
    static let authentication = true
    
    /// Commande de course immédiate
    static let immediateRideBooking = true
    
    /// Suivi en temps réel
    static let realtimeTracking = true
    
    /// Paiement
    static let payment = true
    
    /// Historique des courses
    static let rideHistory = true
    
    /// Évaluation du conducteur
    static let rating = true
    
    // MARK: - Fonctionnalités à Désactiver pour le Lancement (Phase 1)
    
    /// Réservation programmée (désactivée pour le lancement)
    static let scheduledRides = false
    
    /// Partage de trajet (désactivé pour le lancement)
    static let shareRide = false
    
    /// Chat avec conducteur (désactivé pour le lancement)
    static let chatWithDriver = false
    
    /// Favoris avancés (désactivé pour le lancement)
    static let advancedFavorites = false
    
    /// SOS/Emergency (simplifié pour le lancement)
    static let sosEmergency = true // Activé mais version simplifiée
    static let sosAdvanced = false // Fonctionnalités avancées désactivées
    
    /// Promotions avancées (désactivé pour le lancement)
    static let advancedPromotions = false
    
    // MARK: - Configuration Régionale
    
    /// Support multilingue (français et lingala uniquement pour Kinshasa)
    static let multilanguage = true
    static let supportedLanguages: [String] = ["fr", "ln"] // Français et Lingala
    
    // MARK: - Services
    
    /// Firebase Firestore (désactivé si on utilise uniquement WebSocket)
    static let useFirebase = false // Désactivé pour le lancement
    
    /// WebSocket (Socket.io) - Toujours actif pour le temps réel
    static let useWebSocket = true
    
    // MARK: - Mode Développement/Test
    
    /// Mode développement/test (désactivé - utilisation d'un compte de test)
    static let developmentMode = false // Désactivé - utilisation d'un compte de test
    
    /// Code OTP de test (non utilisé en mode production)
    static let testOTPCode = "123456" // Code de test (non utilisé)
    
    /// Bypass OTP en mode développement (désactivé)
    static let bypassOTP = false // Désactivé - utilisation d'un compte de test
    
    // MARK: - Compte de Test
    
    /// Numéro de téléphone du compte de test
    static let testAccountPhoneNumber = "+243900000000"
    
    /// Nom du compte de test
    static let testAccountName = "Compte Test"
    
    /// Rôle du compte de test
    static let testAccountRole: UserRole = .client
    
    // MARK: - Méthodes Utilitaires
    
    /// Vérifie si une fonctionnalité est active
    static func isEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .authentication:
            return authentication
        case .immediateRideBooking:
            return immediateRideBooking
        case .realtimeTracking:
            return realtimeTracking
        case .payment:
            return payment
        case .rideHistory:
            return rideHistory
        case .rating:
            return rating
        case .scheduledRides:
            return scheduledRides
        case .shareRide:
            return shareRide
        case .chatWithDriver:
            return chatWithDriver
        case .advancedFavorites:
            return advancedFavorites
        case .sosEmergency:
            return sosEmergency
        case .sosAdvanced:
            return sosAdvanced
        case .advancedPromotions:
            return advancedPromotions
        case .useFirebase:
            return useFirebase
        case .useWebSocket:
            return useWebSocket
        case .developmentMode:
            return developmentMode
        case .bypassOTP:
            return bypassOTP
        }
    }
}

/// Enumération des fonctionnalités
enum Feature {
    case authentication
    case immediateRideBooking
    case realtimeTracking
    case payment
    case rideHistory
    case rating
    case scheduledRides
    case shareRide
    case chatWithDriver
    case advancedFavorites
    case sosEmergency
    case sosAdvanced
    case advancedPromotions
    case useFirebase
    case useWebSocket
    case developmentMode
    case bypassOTP
}

