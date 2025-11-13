//
//  Ride.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation

enum RideStatus: String, Codable {
    case pending = "pending"           // En attente de conducteur
    case accepted = "accepted"         // Accepté par un conducteur
    case driverArriving = "driver_arriving" // Conducteur en route
    case inProgress = "in_progress"    // Trajet en cours
    case completed = "completed"        // Trajet terminé
    case cancelled = "cancelled"        // Annulé
}

enum PaymentMethod: String, Codable {
    case cash = "cash"
    case mpesa = "mpesa"
    case airtelMoney = "airtel_money"
    case orangeMoney = "orange_money"
    case stripe = "stripe"
    case paypal = "paypal"
}

struct Ride: Identifiable, Codable, Equatable {
    let id: String
    var clientId: String
    var driverId: String? // ID du chauffeur assigné
    var pickupLocation: Location
    var dropoffLocation: Location
    var status: RideStatus
    var estimatedPrice: Double
    var finalPrice: Double?
    var paymentMethod: PaymentMethod?
    var isPaid: Bool
    var distance: Double? // en kilomètres
    var duration: TimeInterval? // en secondes
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var rating: Int? // Note de 1 à 5
    var review: String?
    
    // Position du chauffeur (mise à jour en temps réel)
    var driverLocation: Location? // Position actuelle du chauffeur
    
    init(id: String = UUID().uuidString,
         clientId: String,
         driverId: String? = nil,
         pickupLocation: Location,
         dropoffLocation: Location,
         status: RideStatus = .pending,
         estimatedPrice: Double,
         finalPrice: Double? = nil,
         paymentMethod: PaymentMethod? = nil,
         isPaid: Bool = false,
         distance: Double? = nil,
         duration: TimeInterval? = nil,
         createdAt: Date = Date(),
         startedAt: Date? = nil,
         completedAt: Date? = nil,
         rating: Int? = nil,
         review: String? = nil,
         driverLocation: Location? = nil) {
        self.id = id
        self.clientId = clientId
        self.driverId = driverId
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.status = status
        self.estimatedPrice = estimatedPrice
        self.finalPrice = finalPrice
        self.paymentMethod = paymentMethod
        self.isPaid = isPaid
        self.distance = distance
        self.duration = duration
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.rating = rating
        self.review = review
        self.driverLocation = driverLocation
    }
}

