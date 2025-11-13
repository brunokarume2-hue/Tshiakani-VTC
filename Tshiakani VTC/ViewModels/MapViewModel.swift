//
//  MapViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les cartes et l'affichage des conducteurs
//

import Foundation
import SwiftUI
import Combine
import MapKit
import CoreLocation

class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136), // Kinshasa
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var drivers: [User] = []
    @Published var selectedDriver: User?
    @Published var currentLocation: Location?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showDrivers: Bool = true
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let locationService = LocationService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        startLocationUpdates()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les changements de localisation
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
                if let location = location {
                    self?.updateMapRegion(to: location)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Location Updates
    
    func startLocationUpdates() {
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateCurrentLocation()
        }
    }
    
    func stopLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    private func updateCurrentLocation() {
        if let location = locationService.currentLocation {
            currentLocation = location
            updateMapRegion(to: location)
        }
    }
    
    // MARK: - Map Region
    
    func updateMapRegion(to location: Location) {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func updateMapRegion(to coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Load Drivers
    
    func loadDrivers(near location: Location? = nil) {
        let locationToUse = location ?? currentLocation
        
        guard let location = locationToUse else {
            errorMessage = "Localisation non disponible"
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let nearbyDrivers = try await apiService.getAvailableDrivers(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    radius: 10.0
                )
                
                await MainActor.run {
                    drivers = nearbyDrivers
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement des conducteurs: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Erreur loadDrivers: \(error)")
            }
        }
    }
    
    // MARK: - Select Driver
    
    func selectDriver(_ driver: User) {
        selectedDriver = driver
    }
    
    // MARK: - Toggle Drivers Display
    
    func toggleDriversDisplay() {
        showDrivers.toggle()
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopLocationUpdates()
        cancellables.removeAll()
    }
}

