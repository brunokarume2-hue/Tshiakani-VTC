//
//  DriverSearchViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer la recherche de conducteurs
//

import Foundation
import SwiftUI
import Combine

class DriverSearchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var availableDrivers: [User] = []
    @Published var selectedDriver: User?
    @Published var foundDriver: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSearching: Bool = false
    @Published var searchProgress: Double = 0.0
    
    // Ride
    @Published var ride: Ride?
    @Published var rideId: String?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let rideViewModel = RideViewModel()
    private let realtimeService = RealtimeService.shared
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var searchTimer: Timer?
    private var progressTimer: Timer?
    
    // MARK: - Initialization
    
    init(ride: Ride? = nil, rideId: String? = nil) {
        self.ride = ride
        self.rideId = rideId
        
        setupRealtimeListeners()
    }
    
    // MARK: - Setup
    
    private func setupRealtimeListeners() {
        // Écouter les conducteurs acceptant la course
        realtimeService.onRideAccepted = { [weak self] (ride: Ride) in
            DispatchQueue.main.async {
                if ride.id == self?.rideId || ride.id == self?.ride?.id {
                    // Charger les informations du conducteur
                    if let driverId = ride.driverId {
                        self?.loadDriverInfo(driverId: driverId)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Drivers
    
    func searchDrivers(for ride: Ride) async {
        await MainActor.run {
            isSearching = true
            isLoading = true
            errorMessage = nil
            searchProgress = 0.0
        }
        
        self.ride = ride
        self.rideId = ride.id
        
        // Charger les conducteurs disponibles
        // pickupLocation est non-optionnel dans Ride, donc pas besoin de if let
        await loadAvailableDrivers(near: ride.pickupLocation)
        
        // Simuler la recherche de conducteurs
        startSearchProgress()
    }
    
    private func loadAvailableDrivers(near location: Location) async {
        do {
            let drivers = try await apiService.getAvailableDrivers(
                latitude: location.latitude,
                longitude: location.longitude,
                radius: 10.0
            )
            
            await MainActor.run {
                availableDrivers = drivers
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des conducteurs: \(error.localizedDescription)"
            }
            print("❌ Erreur loadAvailableDrivers: \(error)")
        }
    }
    
    private func startSearchProgress() {
        // Simuler la progression de la recherche
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.searchProgress += 0.02
                
                if self.searchProgress >= 1.0 {
                    timer.invalidate()
                    self.searchProgress = 1.0
                    // La recherche se termine quand un conducteur accepte la course
                }
            }
        }
    }
    
    // MARK: - Load Driver Info
    
    func loadDriverInfo(driverId: String) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Charger les informations du conducteur depuis le backend
                let driver = try await apiService.getDriverInfo(driverId: driverId)
                
                await MainActor.run {
                    foundDriver = driver
                    selectedDriver = driver
                    isSearching = false
                    isLoading = false
                    progressTimer?.invalidate()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement des informations du conducteur: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Erreur loadDriverInfo: \(error)")
            }
        }
    }
    
    // MARK: - Select Driver
    
    func selectDriver(_ driver: User) {
        selectedDriver = driver
    }
    
    // MARK: - Cancel Search
    
    func cancelSearch() {
        isSearching = false
        searchProgress = 0.0
        progressTimer?.invalidate()
        searchTimer?.invalidate()
    }
    
    // MARK: - Cleanup
    
    deinit {
        progressTimer?.invalidate()
        searchTimer?.invalidate()
        cancellables.removeAll()
    }
}

