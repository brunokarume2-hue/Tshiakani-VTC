//
//  VehicleViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer la sélection de véhicule et les estimations de prix
//

import Foundation
import SwiftUI
import Combine

class VehicleViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var vehicleOptions: [VehicleOption] = []
    @Published var selectedVehicleType: VehicleType?
    @Published var priceEstimates: [VehicleType: PriceEstimate] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Location
    @Published var pickupLocation: Location?
    @Published var dropoffLocation: Location?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(pickupLocation: Location? = nil, dropoffLocation: Location? = nil) {
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        
        if let pickup = pickupLocation, let dropoff = dropoffLocation {
            loadPriceEstimates(pickup: pickup, dropoff: dropoff)
        }
    }
    
    // MARK: - Load Price Estimates
    
    func loadPriceEstimates(pickup: Location, dropoff: Location) {
        pickupLocation = pickup
        dropoffLocation = dropoff
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Charger les estimations de prix pour tous les types de véhicules
                var estimates: [VehicleType: PriceEstimate] = [:]
                var options: [VehicleOption] = []
                
                for vehicleType in VehicleType.allCases {
                    let estimate = try await apiService.estimatePrice(
                        pickup: pickup,
                        dropoff: dropoff,
                        vehicleCategory: vehicleType.rawValue
                    )
                    
                    estimates[vehicleType] = estimate
                    
                    let option = VehicleOption(
                        type: vehicleType,
                        price: estimate.price,
                        originalPrice: nil,
                        estimatedWaitTime: 5, // Temps d'attente estimé
                        isSelected: vehicleType == .economy
                    )
                    
                    options.append(option)
                }
                
                await MainActor.run {
                    priceEstimates = estimates
                    vehicleOptions = options
                    selectedVehicleType = .economy
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement des estimations: \(error.localizedDescription)"
                    isLoading = false
                    // Utiliser les prix par défaut
                    vehicleOptions = getDefaultVehicleOptions()
                }
                print("❌ Erreur loadPriceEstimates: \(error)")
            }
        }
    }
    
    private func getDefaultVehicleOptions() -> [VehicleOption] {
        return VehicleType.allCases.map { type in
            VehicleOption(
                type: type,
                price: 1000 * type.multiplier,
                originalPrice: nil,
                estimatedWaitTime: 5,
                isSelected: type == .economy
            )
        }
    }
    
    // MARK: - Select Vehicle
    
    func selectVehicle(_ vehicleType: VehicleType) {
        selectedVehicleType = vehicleType
        
        // Mettre à jour les options
        for index in vehicleOptions.indices {
            vehicleOptions[index].isSelected = vehicleOptions[index].type == vehicleType
        }
    }
    
    // MARK: - Get Price Estimate
    
    func getPriceEstimate(for vehicleType: VehicleType) -> PriceEstimate? {
        return priceEstimates[vehicleType]
    }
    
    // MARK: - Get Selected Price
    
    func getSelectedPrice() -> Double? {
        guard let vehicleType = selectedVehicleType else { return nil }
        return priceEstimates[vehicleType]?.price ?? vehicleOptions.first(where: { $0.type == vehicleType })?.price
    }
}

