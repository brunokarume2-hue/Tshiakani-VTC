//
//  User.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import CoreLocation

enum UserRole: String, Codable, Equatable {
    case client
    case driver
    case admin
}

/// Informations du chauffeur (stockées dans driverInfo JSONB)
struct DriverInfo: Codable, Equatable {
    var isOnline: Bool?
    var status: String?
    var currentLocation: Location?
    var currentRideId: String?
    var rating: Double?
    var totalRides: Int?
    var totalEarnings: Double?
    var licensePlate: String?
    var vehicleType: String?
    var documents: [String: String]?
    var documentsStatus: String?
}

struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var phoneNumber: String
    var email: String?
    var role: UserRole
    var profileImageURL: String?
    var createdAt: Date
    var isVerified: Bool
    var driverInfo: DriverInfo?
    
    init(id: String = UUID().uuidString,
         name: String,
         phoneNumber: String,
         email: String? = nil,
         role: UserRole,
         profileImageURL: String? = nil,
         createdAt: Date = Date(),
         isVerified: Bool = false,
         driverInfo: DriverInfo? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.role = role
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.isVerified = isVerified
        self.driverInfo = driverInfo
    }
    
    // Extension pour faciliter l'accès aux propriétés du chauffeur
    var isDriverAvailable: Bool {
        guard role == .driver, let driverInfo = driverInfo else { return false }
        return driverInfo.isOnline == true && driverInfo.status == "disponible"
    }
    
    var driverCoordinate: CLLocationCoordinate2D? {
        return driverInfo?.currentLocation?.coordinate
    }
}

