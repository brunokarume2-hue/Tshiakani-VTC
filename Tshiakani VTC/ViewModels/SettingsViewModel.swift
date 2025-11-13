//
//  SettingsViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les paramètres de l'application
//

import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedLanguage: String = "Français"
    @Published var selectedCity: String = "Kinshasa"
    @Published var notificationsEnabled: Bool = true
    @Published var locationSharingEnabled: Bool = true
    @Published var biometricEnabled: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Available languages
    @Published var availableLanguages: [String] = ["Français", "Lingala", "Swahili"]
    
    // Available cities
    @Published var availableCities: [String] = ["Kinshasa", "Lubumbashi", "Mbuji-Mayi", "Kananga", "Kisangani"]
    
    // MARK: - Private Properties
    
    private let userPreferencesService = UserPreferencesService.shared
    private let permissionManager = PermissionManager.shared
    private let authViewModel: AuthViewModel
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        setupObservers()
        loadSettings()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les changements de langue
        userPreferencesService.$selectedLanguage
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedLanguage)
        
        // Observer les changements de notifications
        userPreferencesService.$notificationsEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$notificationsEnabled)
        
        // Observer les changements de localisation
        userPreferencesService.$locationEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$locationSharingEnabled)
    }
    
    // MARK: - Load Settings
    
    func loadSettings() {
        selectedLanguage = userPreferencesService.selectedLanguage
        notificationsEnabled = userPreferencesService.notificationsEnabled
        locationSharingEnabled = userPreferencesService.locationEnabled
        
        // Charger la ville depuis UserDefaults
        if let city = UserDefaults.standard.string(forKey: "selected_city") {
            selectedCity = city
        }
        
        // Charger l'état de la biométrie
        biometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
    }
    
    // MARK: - Language
    
    func setLanguage(_ language: String) {
        guard availableLanguages.contains(language) else { return }
        
        selectedLanguage = language
        userPreferencesService.changeLanguage(to: language)
    }
    
    // MARK: - City
    
    func setCity(_ city: String) {
        guard availableCities.contains(city) else { return }
        
        selectedCity = city
        UserDefaults.standard.set(city, forKey: "selected_city")
    }
    
    // MARK: - Notifications
    
    func setNotificationsEnabled(_ enabled: Bool) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Vérifier les permissions
            let hasPermission = await permissionManager.checkNotificationPermission()
            
            if enabled && !hasPermission {
                // Demander la permission
                let granted = await permissionManager.requestNotificationPermission()
                
                if !granted {
                    await MainActor.run {
                        notificationsEnabled = false
                        isLoading = false
                        errorMessage = "La permission de notification n'a pas été accordée"
                    }
                    return
                }
            }
            
            // Mettre à jour les préférences
            await MainActor.run {
                userPreferencesService.notificationsEnabled = enabled
                notificationsEnabled = enabled
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour des notifications: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur setNotificationsEnabled: \(error)")
        }
    }
    
    // MARK: - Location Sharing
    
    func setLocationSharingEnabled(_ enabled: Bool) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Vérifier les permissions
            let hasPermission = await permissionManager.checkLocationPermission()
            
            if enabled && !hasPermission {
                // Demander la permission
                let granted = await permissionManager.requestLocationPermission()
                
                if !granted {
                    await MainActor.run {
                        locationSharingEnabled = false
                        isLoading = false
                        errorMessage = "La permission de localisation n'a pas été accordée"
                    }
                    return
                }
            }
            
            // Mettre à jour les préférences
            await MainActor.run {
                userPreferencesService.locationEnabled = enabled
                locationSharingEnabled = enabled
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour de la localisation: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur setLocationSharingEnabled: \(error)")
        }
    }
    
    // MARK: - Biometric
    
    func setBiometricEnabled(_ enabled: Bool) {
        biometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "biometric_enabled")
    }
    
    // MARK: - Change Password
    
    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            try await authViewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            
            await MainActor.run {
                successMessage = "Mot de passe modifié avec succès"
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du changement de mot de passe: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur changePassword: \(error)")
            return false
        }
    }
    
    // MARK: - Reset Settings
    
    func resetSettings() {
        selectedLanguage = "Français"
        selectedCity = "Kinshasa"
        notificationsEnabled = true
        locationSharingEnabled = true
        biometricEnabled = false
        
        userPreferencesService.resetToDefaults()
        UserDefaults.standard.removeObject(forKey: "selected_city")
        UserDefaults.standard.removeObject(forKey: "biometric_enabled")
    }
    
    // MARK: - Open System Settings
    
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}
