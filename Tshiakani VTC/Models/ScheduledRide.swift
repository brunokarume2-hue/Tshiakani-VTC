//
//  ScheduledRide.swift
//  Tshiakani VTC
//
//  Model pour les courses programmées
//

import Foundation

enum ScheduledRideStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    case completed = "completed"
}

struct ScheduledRide: Identifiable, Codable {
    let id: String
    var pickupLocation: Location
    var dropoffLocation: Location
    let scheduledDate: Date
    var status: ScheduledRideStatus
    var vehicleType: VehicleType
    var paymentMethod: PaymentMethod
    var estimatedPrice: Double?
    let createdAt: Date
    
    // Computed property pour compatibilité
    var vehicleCategory: String? {
        return vehicleType.rawValue
    }
    
    var clientId: String {
        return "" // Sera rempli par le backend
    }
    
    // Computed property pour compatibilité
    var updatedAt: Date {
        return createdAt
    }
    
    // Initializer pour créer depuis les données API
    init(id: String,
         pickupLocation: Location,
         dropoffLocation: Location,
         scheduledDate: Date,
         status: ScheduledRideStatus,
         vehicleType: VehicleType,
         paymentMethod: PaymentMethod,
         estimatedPrice: Double? = nil,
         createdAt: Date) {
        self.id = id
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.scheduledDate = scheduledDate
        self.status = status
        self.vehicleType = vehicleType
        self.paymentMethod = paymentMethod
        self.estimatedPrice = estimatedPrice
        self.createdAt = createdAt
    }
}

