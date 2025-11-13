//
//  AddressViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les adresses sauvegardées et la recherche d'adresses
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit


class AddressViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var savedAddresses: [SavedAddress] = []
    @Published var searchQuery: String = ""
    @Published var searchResults: [PlaceAutocompleteResult] = []
    @Published var selectedLocation: Location?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSearching: Bool = false
    
    // Map selection
    @Published var mapSelectedLocation: Location?
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let googlePlacesService = GooglePlacesService.shared
    private let addressSearchService = AddressSearchService.shared
    private let locationService = LocationService.shared
    private let localStorage = LocalStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        loadSavedAddresses()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les résultats de recherche Google Places
        googlePlacesService.$searchResults
            .receive(on: DispatchQueue.main)
            .assign(to: \.searchResults, on: self)
            .store(in: &cancellables)
        
        googlePlacesService.$isSearching
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSearching, on: self)
            .store(in: &cancellables)
        
        // Observer les résultats de recherche AddressSearchService
        addressSearchService.$searchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completions in
                #if !canImport(GooglePlaces)
                // Convertir les résultats MKLocalSearchCompletion en PlaceAutocompleteResult
                self?.searchResults = completions.map { completion in
                    PlaceAutocompleteResult(
                        id: completion.identifier,
                        primaryText: completion.title,
                        secondaryText: completion.subtitle,
                        placeID: completion.identifier
                    )
                }
                #endif
            }
            .store(in: &cancellables)
        
        addressSearchService.$isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searching in
                #if !canImport(GooglePlaces)
                self?.isSearching = searching
                #endif
            }
            .store(in: &cancellables)
        
        // Observer les changements de requête de recherche
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.searchAddresses(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Address Search
    
    func searchAddresses(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Utiliser Google Places si disponible, sinon utiliser AddressSearchService
        #if canImport(GooglePlaces)
        googlePlacesService.search(query: query)
        #else
        addressSearchService.search(query: query)
        // Les résultats seront convertis dans setupObservers
        #endif
    }
    
    func selectPlace(_ place: PlaceAutocompleteResult) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let location: Location
            
            #if canImport(GooglePlaces)
            let placeDetails = try await googlePlacesService.getPlaceDetails(placeID: place.placeID)
            location = Location(
                latitude: placeDetails.coordinate.latitude,
                longitude: placeDetails.coordinate.longitude,
                address: placeDetails.address
            )
            #else
            // Utiliser AddressSearchService comme fallback
            guard let completion = addressSearchService.searchResults.first(where: { $0.identifier == place.placeID }) else {
                throw NSError(domain: "AddressViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Adresse non trouvée"])
            }
            location = try await addressSearchService.getLocation(from: completion)
            #endif
            
            await MainActor.run {
                selectedLocation = location
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la récupération de l'adresse: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur selectPlace: \(error)")
        }
    }
    
    func selectLocationFromMap(_ coordinate: CLLocationCoordinate2D) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Récupérer l'adresse depuis les coordonnées
            let location = Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            // Geocoder pour obtenir l'adresse
            let address = try await geocodeLocation(location)
            
            let locationWithAddress = Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: address
            )
            
            await MainActor.run {
                mapSelectedLocation = locationWithAddress
                selectedLocation = locationWithAddress
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la récupération de l'adresse: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur selectLocationFromMap: \(error)")
        }
    }
    
    private func geocodeLocation(_ location: Location) async throws -> String {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
        
        guard let placemark = placemarks.first else {
            throw NSError(domain: "AddressViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Adresse non trouvée"])
        }
        
        var addressComponents: [String] = []
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    // MARK: - Saved Addresses
    
    func loadSavedAddresses() {
        // Charger depuis le stockage local
        if let data = UserDefaults.standard.data(forKey: "saved_addresses"),
           let addresses = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            savedAddresses = addresses
        }
    }
    
    func saveAddress(_ address: SavedAddress) {
        // Ajouter ou mettre à jour l'adresse
        if let index = savedAddresses.firstIndex(where: { $0.id == address.id }) {
            savedAddresses[index] = address
        } else {
            savedAddresses.append(address)
        }
        
        // Sauvegarder dans le stockage local
        saveAddressesToLocalStorage()
    }
    
    func deleteAddress(_ address: SavedAddress) {
        savedAddresses.removeAll { $0.id == address.id }
        saveAddressesToLocalStorage()
    }
    
    func toggleFavorite(_ address: SavedAddress) {
        if let index = savedAddresses.firstIndex(where: { $0.id == address.id }) {
            savedAddresses[index].isFavorite.toggle()
            saveAddressesToLocalStorage()
        }
    }
    
    private func saveAddressesToLocalStorage() {
        if let data = try? JSONEncoder().encode(savedAddresses) {
            UserDefaults.standard.set(data, forKey: "saved_addresses")
        }
    }
    
    // MARK: - Current Location
    
    func useCurrentLocation() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            guard let currentLocation = locationService.currentLocation else {
                throw NSError(domain: "AddressViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Localisation non disponible"])
            }
            
            let address = try await geocodeLocation(currentLocation)
            
            let locationWithAddress = Location(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
                address: address
            )
            
            await MainActor.run {
                selectedLocation = locationWithAddress
                mapSelectedLocation = locationWithAddress
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la récupération de la position actuelle: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur useCurrentLocation: \(error)")
        }
    }
    
    // MARK: - Map Region
    
    func updateMapRegion(to location: Location) {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Cleanup
    
    deinit {
        searchTask?.cancel()
        cancellables.removeAll()
    }
}


