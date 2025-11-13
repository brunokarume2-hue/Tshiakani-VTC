//
//  NotificationService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import UserNotifications
import UIKit
import Combine

/// Service de gestion des notifications push et locales
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var hasPermission = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Demande de permission
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Notifications locales
    
    /// Notifier un client qu'un driver a accepté sa course
    func notifyRideAccepted(ride: Ride, driverName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Course acceptée !"
        content.body = "\(driverName) a accepté votre course. Il arrive bientôt."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["rideId": ride.id, "type": "ride_accepted"]
        
        let request = UNNotificationRequest(
            identifier: "ride_accepted_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier un driver d'une nouvelle demande de course
    func notifyNewRideRequest(ride: Ride) {
        let content = UNMutableNotificationContent()
        content.title = "Nouvelle demande de course"
        content.body = "Course disponible à \(ride.pickupLocation.address ?? "proximité")"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["rideId": ride.id, "type": "new_ride_request"]
        
        let request = UNNotificationRequest(
            identifier: "new_ride_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier qu'un driver arrive
    func notifyDriverArriving(ride: Ride, driverName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Votre driver arrive"
        content.body = "\(driverName) est en route vers votre point de départ."
        content.sound = .default
        content.userInfo = ["rideId": ride.id, "type": "driver_arriving"]
        
        let request = UNNotificationRequest(
            identifier: "driver_arriving_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier qu'une course est terminée
    func notifyRideCompleted(ride: Ride) {
        let content = UNMutableNotificationContent()
        content.title = "Course terminée"
        content.body = "Merci d'avoir utilisé Tshiakani VTC ! N'oubliez pas de noter votre conducteur."
        content.sound = .default
        content.userInfo = ["rideId": ride.id, "type": "ride_completed"]
        
        let request = UNNotificationRequest(
            identifier: "ride_completed_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier qu'une course a été annulée
    func notifyRideCancelled(ride: Ride, reason: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Course annulée"
        content.body = reason ?? "La course a été annulée."
        content.sound = .default
        content.userInfo = ["rideId": ride.id, "type": "ride_cancelled"]
        
        let request = UNNotificationRequest(
            identifier: "ride_cancelled_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier un driver qu'une course a été annulée
    func notifyDriverRideCancelled(ride: Ride) {
        let content = UNMutableNotificationContent()
        content.title = "Course annulée"
        content.body = "Le client a annulé la course."
        content.sound = .default
        content.userInfo = ["rideId": ride.id, "type": "ride_cancelled"]
        
        let request = UNNotificationRequest(
            identifier: "driver_ride_cancelled_\(ride.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notifier qu'une alerte SOS a été activée
    func notifySOSActivated(location: Location) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Alerte SOS activée"
        content.body = "Une alerte SOS a été activée. Votre position a été partagée avec les contacts d'urgence."
        content.sound = .defaultCritical
        content.userInfo = [
            "type": "sos_activated",
            "latitude": location.latitude,
            "longitude": location.longitude,
            "address": location.address ?? ""
        ]
        
        let request = UNNotificationRequest(
            identifier: "sos_activated_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Afficher la notification même si l'app est au premier plan
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let rideId = userInfo["rideId"] as? String,
           let type = userInfo["type"] as? String {
            handleNotificationAction(rideId: rideId, type: type)
        }
        
        completionHandler()
    }
    
    private func handleNotificationAction(rideId: String, type: String) {
        // Gérer les actions selon le type de notification
        switch type {
        case "ride_accepted":
            // Ouvrir l'écran de suivi de course
            break
        case "new_ride_request":
            // Ouvrir l'écran de demande de course pour le driver
            break
        default:
            break
        }
    }
}

