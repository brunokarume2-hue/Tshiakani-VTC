//
//  PermissionManager.swift
//  Tshiakani VTC
//
//  Gestionnaire unifié des permissions iOS (Localisation, Notifications, WhatsApp)
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit
import Combine

/// Gestionnaire centralisé des permissions de l'application
@MainActor
class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    // MARK: - Published Properties
    
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isLocationAuthorized: Bool = false
    @Published var isNotificationAuthorized: Bool = false
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkAllPermissions()
    }
    
    // MARK: - Permission Checks
    
    /// Vérifie l'état de toutes les permissions
    func checkAllPermissions() {
        _ = checkLocationPermission()
        Task {
            _ = await checkNotificationPermission()
        }
    }
    
    // MARK: - Location Permission
    
    /// Vérifie le statut de la permission de localisation
    func checkLocationPermission() -> Bool {
        locationStatus = locationManager.authorizationStatus
        isLocationAuthorized = locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
        return isLocationAuthorized
    }
    
    /// Demande la permission de localisation
    func requestLocationPermission() async -> Bool {
        guard locationStatus == .notDetermined else {
            if locationStatus == .denied || locationStatus == .restricted {
                openLocationSettings()
                return false
            }
            return isLocationAuthorized
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        // Attendre que le statut change
        var attempts = 0
        while locationStatus == .notDetermined && attempts < 10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            checkLocationPermission()
            attempts += 1
        }
        
        return isLocationAuthorized
    }
    
    /// Ouvre les paramètres système pour la localisation
    func openLocationSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Notification Permission
    
    /// Vérifie le statut de la permission de notifications
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
            isNotificationAuthorized = settings.authorizationStatus == .authorized
        }
        return isNotificationAuthorized
    }
    
    /// Demande la permission de notifications
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                isNotificationAuthorized = granted
                notificationStatus = granted ? .authorized : .denied
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("Erreur lors de la demande de permission de notification: \(error)")
            return false
        }
    }
    
    /// Ouvre les paramètres système pour les notifications
    func openNotificationSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - WhatsApp Integration
    
    /// Ouvre WhatsApp avec un numéro de téléphone
    /// - Parameter phoneNumber: Numéro au format international (ex: +243820098808)
    func openWhatsApp(phoneNumber: String) {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // URL scheme WhatsApp
        if let whatsappURL = URL(string: "https://wa.me/\(cleanedNumber)") {
            if UIApplication.shared.canOpenURL(whatsappURL) {
                UIApplication.shared.open(whatsappURL)
            } else {
                // Fallback: ouvrir WhatsApp dans l'App Store
                if let appStoreURL = URL(string: "https://apps.apple.com/app/whatsapp-messenger/id310633997") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
    
    /// Vérifie si WhatsApp est installé
    func isWhatsAppInstalled() -> Bool {
        if let whatsappURL = URL(string: "https://wa.me/") {
            return UIApplication.shared.canOpenURL(whatsappURL)
        }
        return false
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erreur de localisation: \(error.localizedDescription)")
    }
}

