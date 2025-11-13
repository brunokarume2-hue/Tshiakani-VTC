//
//  RatingViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les évaluations et les pourboires
//

import Foundation
import SwiftUI
import Combine

class RatingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var rating: Int = 0
    @Published var comment: String = ""
    @Published var tip: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRatingSubmitted: Bool = false
    @Published var currentRide: Ride?
    
    // Tip options
    @Published var tipOptions: [Double] = [0, 5, 10, 15, 20]
    @Published var selectedTipIndex: Int = 2 // 10 FC par défaut
    @Published var customTip: String = ""
    @Published var isCustomTip: Bool = false
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let paymentService = PaymentService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les changements de tip
        $selectedTipIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self = self, index < self.tipOptions.count else { return }
                self.tip = self.tipOptions[index]
                self.isCustomTip = false
            }
            .store(in: &cancellables)
        
        // Observer les changements de customTip
        $customTip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if let self = self, self.isCustomTip, let tipValue = Double(value) {
                    self.tip = tipValue
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Rating
    
    func submitRating(rideId: String, rating: Int, comment: String?, tip: Double? = nil, withPayment: Bool = false) async -> Bool {
        guard rating > 0 && rating <= 5 else {
            await MainActor.run {
                errorMessage = "Veuillez sélectionner une note entre 1 et 5"
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Soumettre l'évaluation
            try await apiService.rateRide(rideId, rating: rating, comment: comment, tip: tip)
            
            await MainActor.run {
                self.rating = rating
                self.comment = comment ?? ""
                self.tip = tip ?? 0.0
                isRatingSubmitted = true
                isLoading = false
            }
            
            // Si un paiement est requis, lancer le processus de paiement
            if withPayment {
                await processPayment(rideId: rideId)
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la soumission de l'évaluation: \(error.localizedDescription)"
                isLoading = false
                isRatingSubmitted = false
            }
            print("❌ Erreur submitRating: \(error)")
            return false
        }
    }
    
    // MARK: - Tip
    
    func selectTip(_ tip: Double) async {
        await MainActor.run {
            if let index = tipOptions.firstIndex(of: tip) {
                selectedTipIndex = index
                self.tip = tip
                isCustomTip = false
            } else {
                // Tip personnalisé
                isCustomTip = true
                customTip = String(tip)
                self.tip = tip
            }
        }
    }
    
    func setCustomTip(_ value: String) {
        customTip = value
        if let tipValue = Double(value) {
            tip = tipValue
            isCustomTip = true
        }
    }
    
    // MARK: - Payment
    
    private func processPayment(rideId: String) async {
        guard tip > 0 else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Utiliser PaymentService pour traiter le pourboire
            try await paymentService.processTip(rideId: rideId, amount: tip)
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du paiement: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur processPayment: \(error)")
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        rating = 0
        comment = ""
        tip = 0.0
        selectedTipIndex = 2
        customTip = ""
        isCustomTip = false
        isRatingSubmitted = false
        errorMessage = nil
        currentRide = nil
    }
    
    // MARK: - Load Ride
    
    func loadRide(rideId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ride = try await apiService.getRideDetails(rideId: rideId)
            
            await MainActor.run {
                currentRide = ride
                // Si la course a déjà une évaluation, charger les données
                if let existingRating = ride.rating {
                    rating = existingRating
                    comment = ride.review ?? ""
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement de la course: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur loadRide: \(error)")
        }
    }
}
