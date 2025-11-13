//
//  AddressSearchService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import MapKit
import Combine

class AddressSearchService: NSObject, ObservableObject {
    static let shared = AddressSearchService()
    
    private let searchCompleter = MKLocalSearchCompleter()
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }
    
    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = query
    }
    
    func getLocation(from completion: MKLocalSearchCompletion) async throws -> Location {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw NSError(domain: "AddressSearchService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Adresse non trouvée"])
        }
        
        // Utiliser placemark pour obtenir les coordonnées et l'adresse
        // Note: placemark est deprecated dans iOS 26.0+ mais toujours fonctionnel
        // et c'est la méthode la plus compatible avec toutes les versions
        guard let location = mapItem.placemark.location else {
            throw NSError(domain: "AddressSearchService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Coordonnées non trouvées"])
        }
        
        let coordinate = location.coordinate
        
        // Construire l'adresse depuis les composants placemark
        let addressComponents = [
            mapItem.name,
            mapItem.placemark.thoroughfare,
            mapItem.placemark.subThoroughfare,
            mapItem.placemark.locality
        ].compactMap { $0 }
        
        let address = addressComponents.isEmpty ? completion.title : addressComponents.joined(separator: ", ")
        
        return Location(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: address.isEmpty ? completion.title : address
        )
    }
}

extension AddressSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Erreur de recherche: \(error.localizedDescription)")
        }
    }
}


