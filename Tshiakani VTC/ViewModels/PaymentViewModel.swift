//
//  PaymentViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les méthodes de paiement et les transactions
//

import Foundation
import SwiftUI
import Combine

class PaymentViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var paymentMethods: [PaymentMethod] = PaymentMethod.availableMethods
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Transactions
    @Published var transactions: [Payment] = []
    @Published var currentTransaction: Payment?
    
    // Stripe
    @Published var stripeClientSecret: String?
    @Published var isProcessingPayment: Bool = false
    @Published var paymentSuccess: Bool = false
    @Published var paymentError: String?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let paymentService = PaymentService.shared
    private let stripeService = StripeService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadPaymentMethods()
        loadTransactions()
        loadDefaultPaymentMethod()
    }
    
    // MARK: - Payment Methods
    
    func loadPaymentMethods() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Charger depuis le backend si disponible
                // Pour l'instant, utiliser les méthodes par défaut
                await MainActor.run {
                    paymentMethods = getDefaultPaymentMethods()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement des méthodes de paiement: \(error.localizedDescription)"
                    isLoading = false
                    paymentMethods = getDefaultPaymentMethods()
                }
            }
        }
    }
    
    private func getDefaultPaymentMethods() -> [PaymentMethod] {
        return PaymentMethod.availableMethods
    }
    
    func addPaymentMethod(_ method: PaymentMethod) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Ajouter la méthode de paiement si elle n'existe pas déjà
        await MainActor.run {
            if !paymentMethods.contains(method) {
                paymentMethods.append(method)
            }
            isLoading = false
        }
    }
    
    func removePaymentMethod(_ method: PaymentMethod) async {
        await MainActor.run {
            paymentMethods.removeAll { $0 == method }
        }
    }
    
    func setDefaultPaymentMethod(_ method: PaymentMethod) async {
        await MainActor.run {
            selectedPaymentMethod = method
            // Sauvegarder la méthode par défaut dans UserDefaults
            UserDefaults.standard.set(method.rawValue, forKey: "default_payment_method")
        }
    }
    
    func selectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod = method
    }
    
    func loadDefaultPaymentMethod() {
        if let savedMethod = UserDefaults.standard.string(forKey: "default_payment_method"),
           let method = PaymentMethod(rawValue: savedMethod) {
            selectedPaymentMethod = method
        } else {
            // Utiliser cash par défaut
            selectedPaymentMethod = .cash
        }
    }
    
    // MARK: - Transactions
    
    func loadTransactions() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Charger depuis le backend
                // Pour l'instant, utiliser une liste vide
                await MainActor.run {
                    transactions = []
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement des transactions: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Payment Processing
    
    func processPayment(amount: Double, rideId: String, method: PaymentMethod, mobileMoneyNumber: String? = nil) async -> Bool {
        await MainActor.run {
            isProcessingPayment = true
            paymentError = nil
            paymentSuccess = false
        }
        
        do {
            // Créer un objet Ride temporaire pour le paiement
            let ride = Ride(
                id: rideId,
                clientId: config.getUserId() ?? "",
                pickupLocation: Location(latitude: 0, longitude: 0),
                dropoffLocation: Location(latitude: 0, longitude: 0),
                status: .completed,
                estimatedPrice: amount,
                finalPrice: amount,
                paymentMethod: method,
                isPaid: false
            )
            
            // Créer un objet PaymentMethod avec les informations nécessaires
            // Note: PaymentMethod dans Payment.swift utilise le type enum
            let payment = try await paymentService.processPayment(
                for: ride,
                method: method,
                mobileMoneyNumber: mobileMoneyNumber
            )
            
            await MainActor.run {
                currentTransaction = payment
                isProcessingPayment = false
                paymentSuccess = payment.status == .completed
            }
            
            // Recharger les transactions
            await loadTransactions()
            
            return paymentSuccess
        } catch {
            await MainActor.run {
                isProcessingPayment = false
                paymentError = error.localizedDescription
                paymentSuccess = false
            }
            print("❌ Erreur processPayment: \(error)")
            return false
        }
    }
    
    func processStripePayment(amount: Double, rideId: String) async throws {
        // Créer un payment intent avec Stripe
        let clientSecret = try await stripeService.createPaymentIntent(amount: amount, currency: "cdf")
        
        await MainActor.run {
            stripeClientSecret = clientSecret
        }
        
        // Le paiement Stripe sera complété dans StripePaymentView
        // Ici on prépare juste le client secret
    }
    
    func confirmStripePayment(paymentIntentId: String, rideId: String) async -> Bool {
        await MainActor.run {
            isProcessingPayment = true
            paymentError = nil
        }
        
        do {
            // Confirmer le paiement via le backend
            try await apiService.confirmPayment(rideId: rideId, paymentIntentId: paymentIntentId)
            
            await MainActor.run {
                isProcessingPayment = false
                paymentSuccess = true
            }
            
            return true
        } catch {
            await MainActor.run {
                isProcessingPayment = false
                paymentError = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Reset
    
    func resetPaymentState() {
        paymentSuccess = false
        paymentError = nil
        stripeClientSecret = nil
        currentTransaction = nil
    }
}

