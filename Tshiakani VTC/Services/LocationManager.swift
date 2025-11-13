//
//  LocationManager.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import CoreLocation
import MapKit
import Combine

/// Gestionnaire de localisation natif iOS avec support complet des autorisations
/// Utilise les dialogues système iOS natifs (comme Uber/Yango)
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: Location?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationError: LocationError?
    @Published var isLocationEnabled = false
    @Published var isUpdatingLocation = false
    
    // Pour les animations
    @Published var shouldAnimateToLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Mettre à jour toutes les 10 mètres
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Autorisations
    
    /// Demande l'autorisation de localisation (déclenche le dialogue système iOS natif)
    /// Cette méthode déclenche automatiquement la popup système iOS
    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            // Déclenche le dialogue système iOS natif
            // L'utilisateur verra : "Autoriser", "Ne pas autoriser", "Autoriser quand l'app est active"
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    /// Demande l'autorisation automatiquement au lancement si nécessaire
    func requestAuthorizationIfNeeded() {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        } else if isAuthorized {
            startUpdatingLocation()
        }
    }
    
    /// Vérifie si l'autorisation est accordée
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Vérifie si l'autorisation peut être demandée
    var canRequestAuthorization: Bool {
        authorizationStatus == .notDetermined
    }
    
    // MARK: - Mise à jour de la localisation
    
    func startUpdatingLocation() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .servicesDisabled
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        isUpdatingLocation = true
        locationError = nil
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
        isUpdatingLocation = false
    }
    
    /// Centre la carte sur la position de l'utilisateur avec animation
    func centerOnUserLocation(completion: ((CLLocationCoordinate2D?) -> Void)? = nil) {
        guard let location = userLocation else {
            if let current = currentLocation {
                let coordinate = CLLocationCoordinate2D(
                    latitude: current.latitude,
                    longitude: current.longitude
                )
                completion?(coordinate)
            } else {
                completion?(nil)
            }
            return
        }
        
        shouldAnimateToLocation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldAnimateToLocation = false
        }
        completion?(location)
    }
    
    // MARK: - Géocodage
    
    func getAddress(from location: Location, completion: @escaping (String?) -> Void) {
        // Utiliser MKLocalSearch pour le géocodage inverse (approche moderne)
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
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
                    mapItem.placemark.subThoroughfare,
                    mapItem.placemark.locality,
                    mapItem.placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address.isEmpty ? nil : address)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Calculs
    
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

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Vérifier la précision de la localisation
        let horizontalAccuracy = location.horizontalAccuracy
        if horizontalAccuracy < 0 || horizontalAccuracy > 100 {
            // Localisation imprécise, ne pas mettre à jour
            locationError = .inaccurate
            return
        }
        
        // Mettre à jour la position utilisateur
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = location.coordinate
            self?.locationError = nil
        }
        
        let newLocation = Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date()
        )
        
        // Obtenir l'adresse
        getAddress(from: newLocation) { [weak self] address in
            var locationWithAddress = newLocation
            locationWithAddress.address = address
            DispatchQueue.main.async {
                self?.currentLocation = locationWithAddress
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        
        switch clError?.code {
        case .denied:
            locationError = .denied
        case .locationUnknown:
            locationError = .unknown
        case .network:
            locationError = .networkError
        default:
            locationError = .unknown
        }
        
        isLocationEnabled = false
        isUpdatingLocation = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationError = nil
            if oldStatus != authorizationStatus {
                // Nouvelle autorisation accordée, démarrer la mise à jour
                startUpdatingLocation()
            }
        case .denied, .restricted:
            locationError = .denied
            isLocationEnabled = false
            stopUpdatingLocation()
        case .notDetermined:
            // En attente de la décision de l'utilisateur
            break
        @unknown default:
            break
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case denied
    case servicesDisabled
    case inaccurate
    case unknown
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .denied:
            return "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
        case .servicesDisabled:
            return "Les services de localisation sont désactivés sur cet appareil."
        case .inaccurate:
            return "La localisation est imprécise. Veuillez vous déplacer dans un endroit plus ouvert."
        case .unknown:
            return "Impossible de déterminer votre position."
        case .networkError:
            return "Erreur réseau lors de la récupération de la localisation."
        }
    }
}

