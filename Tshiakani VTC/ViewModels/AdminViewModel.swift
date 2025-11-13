//
//  AdminViewModel.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import SwiftUI
import Combine

class AdminViewModel: ObservableObject {
    @Published var allRides: [Ride] = []
    @Published var activeRides: [Ride] = []
    @Published var completedRides: [Ride] = []
    @Published var cancelledRides: [Ride] = []
    @Published var allDrivers: [User] = []
    @Published var onlineDrivers: [User] = []
    @Published var allClients: [User] = []
    
    @Published var totalRides = 0
    @Published var totalRevenue = 0.0
    @Published var todayRevenue = 0.0
    @Published var activeDriversCount = 0
    @Published var activeClientsCount = 0
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Écouter les nouvelles courses
        realtimeService.onRideStatusChanged = { [weak self] ride in
            DispatchQueue.main.async {
                self?.updateRide(ride)
            }
        }
        
        // Écouter les nouvelles demandes
        realtimeService.onNewRideRequest = { [weak self] ride in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let alreadyExists = self.allRides.contains(where: { $0.id == ride.id })
                if !alreadyExists {
                    self.allRides.append(ride)
                    self.updateStatistics()
                }
            }
        }
    }
    
    // MARK: - Chargement des données
    
    func loadAllData() {
        isLoading = true
        
        Task {
            await loadRides()
            await loadDrivers()
            await loadClients()
            
            await MainActor.run {
                updateStatistics()
                isLoading = false
            }
        }
    }
    
    func loadRides() async {
        // Charger toutes les courses depuis le backend
        // Simulation pour l'instant
        await MainActor.run {
            // Exemple de données
            allRides = []
            updateRideCategories()
        }
    }
    
    func loadDrivers() async {
        // Charger tous les drivers
        await MainActor.run {
            allDrivers = []
            onlineDrivers = allDrivers.filter { driver in
                guard let isOnline = driver.driverInfo?.isOnline else { return false }
                return isOnline
            }
            activeDriversCount = onlineDrivers.count
        }
    }
    
    func loadClients() async {
        // Charger tous les clients
        await MainActor.run {
            allClients = []
            activeClientsCount = allClients.count
        }
    }
    
    // MARK: - Mise à jour
    
    private func updateRide(_ ride: Ride) {
        if let index = allRides.firstIndex(where: { $0.id == ride.id }) {
            allRides[index] = ride
        } else {
            allRides.append(ride)
        }
        
        updateRideCategories()
        updateStatistics()
    }
    
    private func updateRideCategories() {
        activeRides = allRides.filter { ride in
            ride.status == .pending || ride.status == .accepted || 
            ride.status == .driverArriving || ride.status == .inProgress
        }
        
        completedRides = allRides.filter { $0.status == .completed }
        cancelledRides = allRides.filter { $0.status == .cancelled }
    }
    
    private func updateStatistics() {
        totalRides = allRides.count
        
        totalRevenue = completedRides.reduce(0) { total, ride in
            total + (ride.finalPrice ?? ride.estimatedPrice)
        }
        
        // Revenus d'aujourd'hui
        let today = Calendar.current.startOfDay(for: Date())
        todayRevenue = completedRides
            .filter { ride in
                guard let completedAt = ride.completedAt else { return false }
                return completedAt >= today
            }
            .reduce(0) { total, ride in
                total + (ride.finalPrice ?? ride.estimatedPrice)
            }
        
        activeDriversCount = onlineDrivers.count
        activeClientsCount = allClients.count
    }
    
    // MARK: - Actions Admin
    
    func suspendDriver(_ driverId: String) {
        // Suspendre un driver
        if allDrivers.contains(where: { $0.id == driverId }) {
            // Mettre à jour le statut du driver
            // Dans une vraie app, cela appellerait l'API
        }
    }
    
    func viewRideDetails(_ rideId: String) -> Ride? {
        return allRides.first(where: { $0.id == rideId })
    }
    
    func getRidesByStatus(_ status: RideStatus) -> [Ride] {
        return allRides.filter { $0.status == status }
    }
    
    func getRidesByDate(_ date: Date) -> [Ride] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        
        return allRides.filter { ride in
            ride.createdAt >= dayStart && ride.createdAt < dayEnd
        }
    }
}

