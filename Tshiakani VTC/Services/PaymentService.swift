//
//  PaymentService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import Combine

class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    @Published var paymentHistory: [Payment] = []
    
    private init() {}
    
    func processPayment(for ride: Ride, method: PaymentMethod, mobileMoneyNumber: String? = nil) async throws -> Payment {
        // Simulation d'un paiement
        // Dans une vraie application, cela appellerait une API de paiement
        
        let payment = Payment(
            rideId: ride.id,
            userId: ride.clientId,
            amount: ride.finalPrice ?? ride.estimatedPrice,
            method: method,
            status: .processing,
            mobileMoneyNumber: mobileMoneyNumber
        )
        
        // Simuler le traitement du paiement
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
        
        var completedPayment = payment
        completedPayment.status = .completed
        completedPayment.transactionId = UUID().uuidString
        completedPayment.completedAt = Date()
        
        await MainActor.run {
            paymentHistory.append(completedPayment)
        }
        
        return completedPayment
    }
    
    func getPaymentHistory(for userId: String) -> [Payment] {
        return paymentHistory.filter { $0.userId == userId }
    }
    
    // MARK: - Payment Methods
    
    func processCashPayment(rideId: String, amount: Double) async throws {
        // Pour le paiement en espèces, on marque juste la course comme payée
        // Le paiement sera confirmé directement
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
    }
    
    func processMobileMoneyPayment(rideId: String, amount: Double, method: PaymentMethod, mobileMoneyNumber: String? = nil) async throws {
        // Simuler le traitement du paiement mobile money
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 secondes
    }
    
    func confirmPayment(rideId: String, paymentIntentId: String) async throws {
        // Confirmer le paiement via le backend
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
    }
    
    func processTip(rideId: String, amount: Double) async throws {
        // Traiter le pourboire
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
    }
}

