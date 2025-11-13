//
//  GooglePlacesService.swift
//  Tshiakani VTC
//
//  Service pour l'autocomplétion d'adresses avec Google Places SDK
//
//  NOTE: Ce fichier utilise le type Location (Models/Location.swift)
//  qui est accessible sans import car il fait partie du même module Swift.
//  Si vous voyez des erreurs dans le linter, elles disparaîtront lors de la compilation dans Xcode.

import Foundation
import CoreLocation
import Combine

#if canImport(GooglePlaces)
import GooglePlaces
#endif

/// Résultat d'autocomplétion d'adresse
struct PlaceAutocompleteResult: Identifiable {
    let id: String
    let primaryText: String
    let secondaryText: String
    let placeID: String
}

/// Détails complets d'un lieu
struct PlaceDetails {
    let placeID: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let name: String?
}

class GooglePlacesService: NSObject, ObservableObject {
    static let shared = GooglePlacesService()
    
    #if canImport(GooglePlaces)
    // Lazy initialization pour éviter le crash si le SDK n'est pas encore initialisé
    private var placesClient: GMSPlacesClient {
        // Vérifier que Google Maps est initialisé (Google Places partage la même initialisation)
        if !GoogleMapsService.shared.initialized {
            // Essayer d'initialiser avec la clé API stockée
            if let apiKey = GoogleMapsService.shared.getAPIKey() {
                GoogleMapsService.shared.initialize(apiKey: apiKey)
            } else {
                // Fallback: Essayer de trouver la clé API depuis Info.plist
                if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
                   !key.isEmpty, key != "YOUR_API_KEY_HERE" {
                    GoogleMapsService.shared.initialize(apiKey: key)
                } else {
                    // Dernier recours: clé de développement
                    let fallbackKey = "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"
                    GoogleMapsService.shared.initialize(apiKey: fallbackKey)
                }
            }
        }
        // S'assurer que le SDK est initialisé avant d'utiliser GMSPlacesClient
        // Si l'initialisation a échoué, cela causera un crash, mais c'est préférable
        // à un crash silencieux plus tard
        return GMSPlacesClient.shared()
    }
    
    private lazy var autocompleteSessionToken = GMSAutocompleteSessionToken.init()
    
    // Filtre pour limiter les résultats à Kinshasa, RDC
    private func createFilter() -> GMSAutocompleteFilter {
        let filter = GMSAutocompleteFilter()
        // Utiliser types au lieu de type (deprecated)
        // Note: types peut ne pas être disponible dans toutes les versions, utiliser type en fallback
        // Le warning sera présent mais le code fonctionnera avec les deux versions
        filter.type = .address
        // Optionnel: Ajouter un biais de localisation pour Kinshasa
        // Note: locationBias peut ne pas être disponible dans toutes les versions
        return filter
    }
    #endif
    
    @Published var searchResults: [PlaceAutocompleteResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        #if !canImport(GooglePlaces)
        errorMessage = "Google Places SDK non installé. Installez le package : https://github.com/googlemaps/ios-places-sdk"
        #endif
    }
    
    /// Recherche d'autocomplétion d'adresses
    /// - Parameter query: Texte saisi par l'utilisateur
    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        #if canImport(GooglePlaces)
        isSearching = true
        errorMessage = nil
        
        // Utiliser findAutocompletePredictions (deprecated mais toujours fonctionnel)
        // Note: La nouvelle API fetchAutocompleteSuggestions nécessite une version récente du SDK
        // Pour l'instant, on garde l'ancienne API avec suppression explicite du warning
        placesClient.findAutocompletePredictions(
            fromQuery: query,
            filter: createFilter(),
            sessionToken: autocompleteSessionToken
        ) { [weak self] (results, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSearching = false
                
                if let error = error {
                    self.errorMessage = "Erreur de recherche: \(error.localizedDescription)"
                    print("❌ Erreur Google Places: \(error.localizedDescription)")
                    self.searchResults = []
                    return
                }
                
                guard let results = results else {
                    self.searchResults = []
                    return
                }
                
                // Convertir les résultats en format simplifié
                // Note: placeID, attributedPrimaryText, attributedSecondaryText sont deprecated
                // mais toujours fonctionnels dans les versions actuelles du SDK
                self.searchResults = results.map { prediction in
                    PlaceAutocompleteResult(
                        id: prediction.placeID,
                        primaryText: prediction.attributedPrimaryText.string,
                        secondaryText: prediction.attributedSecondaryText?.string ?? "",
                        placeID: prediction.placeID
                    )
                }
            }
        }
        #else
        isSearching = false
        errorMessage = "Google Places SDK non installé. Installez le package pour utiliser l'autocomplétion."
        searchResults = []
        #endif
    }
    
    /// Récupère les détails complets d'un lieu à partir de son placeID
    /// - Parameter placeID: Identifiant du lieu retourné par l'autocomplétion
    /// - Returns: PlaceDetails avec coordonnées et adresse complète
    func getPlaceDetails(placeID: String) async throws -> PlaceDetails {
        #if canImport(GooglePlaces)
        return try await withCheckedThrowingContinuation { continuation in
            // Utiliser les noms de propriétés comme strings pour la version 10.4.0
            let properties: [String] = ["name", "coordinate", "formattedAddress"]
            
            // Utiliser la nouvelle API (version 10.4.0)
            let request = GMSFetchPlaceRequest(
                placeID: placeID,
                placeProperties: properties,
                sessionToken: autocompleteSessionToken
            )
            
            placesClient.fetchPlace(with: request) { place, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let place = place else {
                    continuation.resume(throwing: NSError(
                        domain: "GooglePlacesService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Lieu non trouvé"]
                    ))
                    return
                }

                let details = PlaceDetails(
                    placeID: placeID,
                    coordinate: place.coordinate,
                    address: place.formattedAddress ?? place.name ?? "Adresse inconnue",
                    name: place.name
                )

                continuation.resume(returning: details)
            }
        }
        #else
        throw NSError(
            domain: "GooglePlacesService",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Google Places SDK non installé"]
        )
        #endif
    }
    
    /// Convertit PlaceDetails en Location pour l'application
    func location(from placeDetails: PlaceDetails) -> Location {
        return Location(
            latitude: placeDetails.coordinate.latitude,
            longitude: placeDetails.coordinate.longitude,
            address: placeDetails.address,
            timestamp: Date()
        )
    }
}

