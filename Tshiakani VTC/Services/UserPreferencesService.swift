//
//  UserPreferencesService.swift
//  Tshiakani VTC
//
//  Service de gestion des préférences utilisateur
//

import Foundation
import Combine

/// Service pour gérer les préférences utilisateur (langue, notifications, etc.)
@MainActor
class UserPreferencesService: ObservableObject {
    static let shared = UserPreferencesService()
    
    // MARK: - Published Properties
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "app_language")
            Localizable.shared.currentLanguage = languageCode
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
        }
    }
    
    @Published var locationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(locationEnabled, forKey: "location_enabled")
        }
    }
    
    // MARK: - Computed Properties
    
    var languageCode: String {
        switch selectedLanguage {
        case "Français":
            return "fr"
        case "Lingala":
            return "ln"
        case "Swahili":
            return "sw"
        default:
            return "fr"
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Charger la langue depuis UserDefaults ou utiliser la langue actuelle de Localizable
        let currentLangCode = Localizable.shared.currentLanguage
        switch currentLangCode {
        case "fr":
            self.selectedLanguage = "Français"
        case "ln":
            self.selectedLanguage = "Lingala"
        case "sw":
            self.selectedLanguage = "Swahili"
        default:
            self.selectedLanguage = "Français"
        }
        
        // Charger les autres préférences
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notifications_enabled") as? Bool ?? true
        self.locationEnabled = UserDefaults.standard.object(forKey: "location_enabled") as? Bool ?? true
    }
    
    // MARK: - Language Management
    
    /// Change la langue de l'application
    func changeLanguage(to language: String) {
        selectedLanguage = language
    }
    
    /// Récupère la langue actuelle
    func getLanguage() -> String {
        return selectedLanguage
    }
    
    /// Définit la langue
    func setLanguage(_ language: String) {
        selectedLanguage = language
    }
    
    // MARK: - City Management
    
    /// Récupère la ville sélectionnée
    func getCity() -> String {
        return UserDefaults.standard.string(forKey: "selected_city") ?? "Kinshasa"
    }
    
    /// Définit la ville
    func setCity(_ city: String) {
        UserDefaults.standard.set(city, forKey: "selected_city")
    }
    
    // MARK: - Notifications
    
    /// Récupère l'état des notifications
    func getNotificationsEnabled() -> Bool {
        return notificationsEnabled
    }
    
    /// Définit l'état des notifications
    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
    }
    
    // MARK: - Location Sharing
    
    /// Récupère l'état du partage de localisation
    func getLocationSharingEnabled() -> Bool {
        return locationEnabled
    }
    
    /// Définit l'état du partage de localisation
    func setLocationSharingEnabled(_ enabled: Bool) {
        locationEnabled = enabled
    }
    
    /// Réinitialise les préférences aux valeurs par défaut
    func resetToDefaults() {
        selectedLanguage = "Français"
        notificationsEnabled = true
        locationEnabled = true
    }
}

