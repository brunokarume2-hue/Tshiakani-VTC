//
//  ScheduledRideViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les courses programmées
//

import Foundation
import SwiftUI
import Combine

class ScheduledRideViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var scheduledRides: [ScheduledRide] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var selectedTime: Date = Date()
    @Published var pickupLocation: Location?
    @Published var dropoffLocation: Location?
    @Published var estimatedPrice: Double = 0
    @Published var estimatedDistance: Double = 0
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadScheduledRides()
        }
    }
    
    // MARK: - Load Scheduled Rides
    
    func loadScheduledRides() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let rides = try await apiService.getScheduledRides()
            
            await MainActor.run {
                scheduledRides = rides
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des courses programmées: \(error.localizedDescription)"
                isLoading = false
                scheduledRides = []
            }
            print("❌ Erreur loadScheduledRides: \(error)")
        }
    }
    
    // MARK: - Create Scheduled Ride
    
    func createScheduledRide(
        pickupLocation: Location,
        dropoffLocation: Location,
        scheduledDate: Date,
        vehicleType: VehicleType = .economy,
        paymentMethod: PaymentMethod = .cash
    ) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ride = try await apiService.createScheduledRide(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledDate: scheduledDate,
                vehicleType: vehicleType,
                paymentMethod: paymentMethod
            )
            
            await MainActor.run {
                scheduledRides.append(ride)
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création de la course programmée: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur createScheduledRide: \(error)")
            return false
        }
    }
    
    // MARK: - Cancel Scheduled Ride
    
    func cancelScheduledRide(_ rideId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.cancelScheduledRide(scheduledRideId: rideId)
            
            await MainActor.run {
                scheduledRides.removeAll { $0.id == rideId }
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'annulation de la course programmée: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur cancelScheduledRide: \(error)")
            return false
        }
    }
    
    // MARK: - Update Scheduled Ride
    
    func updateScheduledRide(
        _ rideId: String,
        pickupLocation: Location? = nil,
        dropoffLocation: Location? = nil,
        scheduledDate: Date? = nil
    ) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ride = try await apiService.updateScheduledRide(
                rideId,
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledDate: scheduledDate
            )
            
            await MainActor.run {
                if let index = scheduledRides.firstIndex(where: { $0.id == rideId }) {
                    scheduledRides[index] = ride
                }
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur updateScheduledRide: \(error)")
            return false
        }
    }
}

