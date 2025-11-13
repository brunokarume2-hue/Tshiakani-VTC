//
//  DataTransformService.swift
//  Tshiakani VTC
//
//  Service de transformation des données entre formats iOS et backend
//  Convertit les modèles Swift en format JSON backend et vice versa
//

import Foundation

/// Service de transformation des données
class DataTransformService {
    static let shared = DataTransformService()
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {}
    
    // MARK: - Transformation Ride
    
    /// Convertit un Ride iOS en dictionnaire pour le backend
    func rideToBackend(_ ride: Ride) -> [String: Any] {
        return [
            "pickupLocation": locationToBackend(ride.pickupLocation),
            "dropoffLocation": locationToBackend(ride.dropoffLocation),
            "distance": ride.distance ?? 0.0,
            "status": ride.status.rawValue
        ]
    }
    
    /// Convertit une réponse backend en Ride iOS
    func rideFromBackend(_ data: [String: Any]) -> Ride? {
        guard let id = data["id"] as? Int ?? (data["id"] as? String).flatMap({ Int($0) }),
              let clientId = data["clientId"] as? Int ?? (data["clientId"] as? String).flatMap({ Int($0) }),
              let pickupLocationData = data["pickupLocation"] as? [String: Any],
              let dropoffLocationData = data["dropoffLocation"] as? [String: Any],
              let statusString = data["status"] as? String,
              let status = RideStatus(rawValue: statusString),
              let estimatedPrice = data["estimatedPrice"] as? Double else {
            return nil
        }
        
        guard let pickupLocation = locationFromBackend(pickupLocationData),
              let dropoffLocation = locationFromBackend(dropoffLocationData) else {
            return nil
        }
        
        let createdAt: Date
        if let createdAtString = data["createdAt"] as? String {
            createdAt = dateFormatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        var ride = Ride(
            id: String(id),
            clientId: String(clientId),
            driverId: (data["driverId"] as? Int).map { String($0) } ?? (data["driverId"] as? String),
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            status: status,
            estimatedPrice: estimatedPrice,
            finalPrice: data["finalPrice"] as? Double,
            distance: data["distance"] as? Double,
            createdAt: createdAt
        )
        
        // Ajouter les autres propriétés optionnelles
        if let startedAtString = data["startedAt"] as? String {
            ride.startedAt = dateFormatter.date(from: startedAtString) ?? ISO8601DateFormatter().date(from: startedAtString)
        }
        
        if let completedAtString = data["completedAt"] as? String {
            ride.completedAt = dateFormatter.date(from: completedAtString) ?? ISO8601DateFormatter().date(from: completedAtString)
        }
        
        if let rating = data["rating"] as? Int {
            ride.rating = rating
        }
        
        if let review = data["review"] as? String {
            ride.review = review
        }
        
        if let paymentMethodString = data["paymentMethod"] as? String,
           let paymentMethod = PaymentMethod(rawValue: paymentMethodString) {
            ride.paymentMethod = paymentMethod
        }
        
        if let isPaid = data["isPaid"] as? Bool {
            ride.isPaid = isPaid
        }
        
        return ride
    }
    
    /// Convertit un tableau de réponses backend en tableau de Rides iOS
    func ridesFromBackend(_ dataArray: [[String: Any]]) -> [Ride] {
        return dataArray.compactMap { rideFromBackend($0) }
    }
    
    // MARK: - Transformation Location
    
    /// Convertit une Location iOS en dictionnaire pour le backend
    func locationToBackend(_ location: Location) -> [String: Any] {
        var result: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude
        ]
        
        if let address = location.address {
            result["address"] = address
        }
        
        return result
    }
    
    /// Convertit une réponse backend en Location iOS
    func locationFromBackend(_ data: [String: Any]) -> Location? {
        guard let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double else {
            return nil
        }
        
        let address = data["address"] as? String
        
        var timestamp = Date()
        if let timestampString = data["timestamp"] as? String {
            timestamp = dateFormatter.date(from: timestampString) ?? ISO8601DateFormatter().date(from: timestampString) ?? Date()
        } else if let timestampDouble = data["timestamp"] as? TimeInterval {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        }
        
        return Location(
            latitude: latitude,
            longitude: longitude,
            address: address,
            timestamp: timestamp
        )
    }
    
    // MARK: - Transformation User
    
    /// Convertit un User iOS en dictionnaire pour le backend
    func userToBackend(_ user: User) -> [String: Any] {
        var result: [String: Any] = [
            "name": user.name,
            "phoneNumber": user.phoneNumber,
            "role": user.role.rawValue,
            "isVerified": user.isVerified
        ]
        
        if let email = user.email {
            result["email"] = email
        }
        
        if let profileImageURL = user.profileImageURL {
            result["profileImageURL"] = profileImageURL
        }
        
        if let driverInfo = user.driverInfo {
            result["driverInfo"] = driverInfoToBackend(driverInfo)
        }
        
        return result
    }
    
    /// Convertit une réponse backend en User iOS
    func userFromBackend(_ data: [String: Any]) -> User? {
        guard let id = data["id"] as? Int ?? (data["id"] as? String).flatMap({ Int($0) }),
              let name = data["name"] as? String,
              let phoneNumber = data["phoneNumber"] as? String,
              let roleString = data["role"] as? String,
              let role = UserRole(rawValue: roleString) else {
            return nil
        }
        
        let createdAt: Date
        if let createdAtString = data["createdAt"] as? String {
            createdAt = dateFormatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        var user = User(
            id: String(id),
            name: name,
            phoneNumber: phoneNumber,
            email: data["email"] as? String,
            role: role,
            profileImageURL: data["profileImageURL"] as? String,
            createdAt: createdAt,
            isVerified: data["isVerified"] as? Bool ?? false
        )
        
        if let driverInfoData = data["driverInfo"] as? [String: Any] {
            user.driverInfo = driverInfoFromBackend(driverInfoData)
        }
        
        return user
    }
    
    /// Convertit un tableau de réponses backend en tableau de Users iOS
    func usersFromBackend(_ dataArray: [[String: Any]]) -> [User] {
        return dataArray.compactMap { userFromBackend($0) }
    }
    
    // MARK: - Transformation DriverInfo
    
    /// Convertit un DriverInfo iOS en dictionnaire pour le backend
    func driverInfoToBackend(_ driverInfo: DriverInfo) -> [String: Any] {
        var result: [String: Any] = [:]
        
        if let isOnline = driverInfo.isOnline {
            result["isOnline"] = isOnline
        }
        
        if let status = driverInfo.status {
            result["status"] = status
        }
        
        if let currentLocation = driverInfo.currentLocation {
            result["currentLocation"] = locationToBackend(currentLocation)
        }
        
        if let currentRideId = driverInfo.currentRideId {
            result["currentRideId"] = currentRideId
        }
        
        if let rating = driverInfo.rating {
            result["rating"] = rating
        }
        
        if let totalRides = driverInfo.totalRides {
            result["totalRides"] = totalRides
        }
        
        if let totalEarnings = driverInfo.totalEarnings {
            result["totalEarnings"] = totalEarnings
        }
        
        if let licensePlate = driverInfo.licensePlate {
            result["licensePlate"] = licensePlate
        }
        
        if let vehicleType = driverInfo.vehicleType {
            result["vehicleType"] = vehicleType
        }
        
        if let documents = driverInfo.documents {
            result["documents"] = documents
        }
        
        if let documentsStatus = driverInfo.documentsStatus {
            result["documentsStatus"] = documentsStatus
        }
        
        return result
    }
    
    /// Convertit une réponse backend en DriverInfo iOS
    func driverInfoFromBackend(_ data: [String: Any]) -> DriverInfo? {
        var driverInfo = DriverInfo()
        
        driverInfo.isOnline = data["isOnline"] as? Bool
        driverInfo.status = data["status"] as? String
        
        if let locationData = data["currentLocation"] as? [String: Any] {
            driverInfo.currentLocation = locationFromBackend(locationData)
        }
        
        driverInfo.currentRideId = data["currentRideId"] as? String
        driverInfo.rating = data["rating"] as? Double
        driverInfo.totalRides = data["totalRides"] as? Int
        driverInfo.totalEarnings = data["totalEarnings"] as? Double
        driverInfo.licensePlate = data["licensePlate"] as? String
        driverInfo.vehicleType = data["vehicleType"] as? String
        driverInfo.documents = data["documents"] as? [String: String]
        driverInfo.documentsStatus = data["documentsStatus"] as? String
        
        return driverInfo
    }
    
    // MARK: - Transformation Socket.io Messages
    
    /// Convertit un message Socket.io en dictionnaire
    func parseSocketMessage(_ data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("Erreur parsing message Socket.io: \(error)")
            return nil
        }
    }
    
    /// Convertit un dictionnaire en message Socket.io (JSON)
    func socketMessageFromDictionary(_ dict: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

