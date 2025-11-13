//
//  Location.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import CoreLocation

struct Location: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var timestamp: Date
    
    init(latitude: Double, longitude: Double, address: String? = nil, timestamp: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.timestamp = timestamp
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func distance(to location: Location) -> Double {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return from.distance(from: to) / 1000.0 // Distance en kilomètres
    }
}

