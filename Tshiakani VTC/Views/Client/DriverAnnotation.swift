//
//  DriverAnnotation.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import MapKit

struct DriverAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D, driverId: String) {
        self.id = driverId
        self.coordinate = coordinate
    }
}

