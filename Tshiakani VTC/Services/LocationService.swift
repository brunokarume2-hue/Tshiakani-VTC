//
//  LocationService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: Location?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Mettre à jour toutes les 10 mètres
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getAddress(from location: Location, completion: @escaping (String?) -> Void) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        
        // Utiliser MKLocalSearch pour le géocodage inverse (approche moderne)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(coordinate.latitude), \(coordinate.longitude)"
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Erreur de géocodage: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let mapItem = response?.mapItems.first {
                // Note: placemark est deprecated dans iOS 26.0+ mais toujours fonctionnel
                // Utiliser placemark pour compatibilité avec toutes les versions
                let address = [
                    mapItem.name,
                    mapItem.placemark.thoroughfare,
                    mapItem.placemark.locality
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address.isEmpty ? nil : address)
            } else {
                completion(nil)
            }
        }
    }
    
    func calculateDistance(from: Location, to: Location) -> Double {
        return from.distance(to: to)
    }
    
    func estimatePrice(distance: Double) -> Double {
        // Tarif de base: 500 CDF + 200 CDF par km
        let basePrice = 500.0
        let pricePerKm = 200.0
        return basePrice + (distance * pricePerKm)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let newLocation = Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date()
        )
        
        // Obtenir l'adresse
        getAddress(from: newLocation) { [weak self] address in
            var locationWithAddress = newLocation
            locationWithAddress.address = address
            self?.currentLocation = locationWithAddress
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Erreur de localisation: \(error.localizedDescription)"
        print("Erreur de localisation: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
        case .notDetermined:
            requestAuthorization()
        @unknown default:
            break
        }
    }
}

