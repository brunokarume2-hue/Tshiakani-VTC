//
//  BookingViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les réservations de courses
//

import Foundation
import SwiftUI
import Combine

class BookingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var pickupLocation: Location?
    @Published var dropoffLocation: Location?
    @Published var selectedVehicleType: VehicleType = .economy
    @Published var selectedPaymentMethod: PaymentMethod = .cash
    @Published var priceEstimate: PriceEstimate?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isConfirmed: Bool = false
    @Published var currentRide: Ride?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let rideViewModel = RideViewModel()
    private let vehicleViewModel = VehicleViewModel()
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les changements de type de véhicule
        vehicleViewModel.$selectedVehicleType
            .receive(on: DispatchQueue.main)
            .compactMap { $0 } // Convertir VehicleType? en VehicleType
            .assign(to: \.selectedVehicleType, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Set Locations
    
    func setPickupLocation(_ location: Location) {
        pickupLocation = location
        vehicleViewModel.pickupLocation = location
        
        if let dropoff = dropoffLocation {
            vehicleViewModel.loadPriceEstimates(pickup: location, dropoff: dropoff)
        }
    }
    
    func setDropoffLocation(_ location: Location) {
        dropoffLocation = location
        vehicleViewModel.dropoffLocation = location
        
        if let pickup = pickupLocation {
            vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: location)
        }
    }
    
    // MARK: - Select Vehicle
    
    func selectVehicle(_ vehicleType: VehicleType) {
        selectedVehicleType = vehicleType
        vehicleViewModel.selectVehicle(vehicleType)
        priceEstimate = vehicleViewModel.getPriceEstimate(for: vehicleType)
    }
    
    // MARK: - Select Payment Method
    
    func selectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod = method
    }
    
    // MARK: - Estimate Price
    
    func estimatePrice() async {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
            await MainActor.run {
                errorMessage = "Veuillez sélectionner les adresses de départ et d'arrivée"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let estimate = try await apiService.estimatePrice(
                pickup: pickup,
                dropoff: dropoff,
                vehicleCategory: selectedVehicleType.rawValue
            )
            
            await MainActor.run {
                priceEstimate = estimate
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'estimation du prix: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur estimatePrice: \(error)")
        }
    }
    
    // MARK: - Confirm Booking
    
    func confirmBooking() async -> Bool {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
            await MainActor.run {
                errorMessage = "Veuillez sélectionner les adresses de départ et d'arrivée"
            }
            return false
        }
        
        guard let userId = config.getUserId() else {
            await MainActor.run {
                errorMessage = "Vous devez être connecté"
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Créer la course via RideViewModel
            await rideViewModel.requestRide(
                pickup: pickup,
                dropoff: dropoff,
                userId: userId
            )
            
            if let ride = rideViewModel.currentRide {
                await MainActor.run {
                    currentRide = ride
                    isConfirmed = true
                    isLoading = false
                }
                return true
            } else {
                await MainActor.run {
                    errorMessage = rideViewModel.errorMessage ?? "Erreur lors de la création de la course"
                    isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la confirmation de la réservation: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur confirmBooking: \(error)")
            return false
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        pickupLocation = nil
        dropoffLocation = nil
        selectedVehicleType = .economy
        selectedPaymentMethod = .cash
        priceEstimate = nil
        isConfirmed = false
        currentRide = nil
        errorMessage = nil
    }
}

