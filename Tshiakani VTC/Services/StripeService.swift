//
//  StripeService.swift
//  Tshiakani VTC
//
//  Service pour l'intégration Stripe iOS SDK
//  Note: Pour utiliser le vrai SDK Stripe, installez via Swift Package Manager:
//  https://github.com/stripe/stripe-ios
//

import Foundation
import Combine

/// Service pour gérer les paiements Stripe
class StripeService: ObservableObject {
    static let shared = StripeService()
    
    // Clé publique Stripe (à configurer depuis les variables d'environnement)
    // En production, récupérez-la depuis votre backend ou Info.plist
    private let publishableKey: String = {
        // Vous pouvez stocker cette clé dans Info.plist ou la récupérer depuis le backend
        if let key = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String {
            return key
        }
        // Valeur par défaut pour le développement (remplacez par votre clé de test)
        return "pk_test_..." // À remplacer par votre clé publique Stripe
    }()
    
    private let baseURL: String = {
        // URL de votre backend Render
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            return url
        }
        return "https://votre-api.onrender.com/api" // À remplacer par votre URL Render
    }()
    
    private init() {}
    
    // MARK: - Génération de Token Stripe (simplifié)
    
    /// Génère un token Stripe à partir des informations de carte
    /// Note: Dans une vraie implémentation, utilisez le Stripe iOS SDK
    /// https://stripe.com/docs/payments/accept-a-payment?platform=ios
    func createPaymentToken(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String,
        cardholderName: String
    ) async throws -> String {
        // IMPORTANT: Dans une vraie application, utilisez le Stripe iOS SDK
        // qui génère un token sécurisé côté client sans envoyer les données de carte au backend
        
        // Pour l'instant, on simule la génération d'un token
        // En production, utilisez: StripeAPI.defaultPublishableKey = publishableKey
        // puis STPAPIClient.shared.createToken(...)
        
        // Simulation d'un token Stripe (format: tok_xxxxx)
        let simulatedToken = "tok_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))"
        
        // Dans une vraie implémentation, vous utiliseriez:
        /*
        import Stripe
        import StripePaymentSheet
        
        StripeAPI.defaultPublishableKey = publishableKey
        
        let cardParams = STPCardParams()
        cardParams.number = cardNumber
        cardParams.expMonth = UInt(expiryMonth)
        cardParams.expYear = UInt(expiryYear)
        cardParams.cvc = cvc
        
        let client = STPAPIClient.shared
        let token = try await client.createToken(withCard: cardParams)
        return token.tokenId
        */
        
        return simulatedToken
    }
    
    // MARK: - Pré-autorisation de paiement
    
    /// Pré-autorise un paiement pour une course
    /// - Parameters:
    ///   - rideId: ID de la course
    ///   - stripeToken: Token Stripe généré
    ///   - amount: Montant à pré-autoriser (optionnel)
    /// - Returns: PaymentIntent avec clientSecret pour confirmation
    func preauthorizePayment(
        rideId: String,
        stripeToken: String,
        amount: Double? = nil
    ) async throws -> StripePaymentIntent {
        guard let url = URL(string: "\(baseURL)/paiements/preauthorize") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token JWT si disponible
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = [
            "rideId": Int(rideId) ?? 0,
            "stripeToken": stripeToken
        ]
        
        if let amount = amount {
            body["amount"] = amount
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            throw StripeError.serverError(message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(StripePreauthorizeResponse.self, from: data)
        
        guard responseData.success else {
            throw StripeError.serverError(message: responseData.error ?? "Erreur inconnue")
        }
        
        return responseData.paymentIntent
    }
    
    // MARK: - Create Payment Intent
    
    /// Crée un PaymentIntent Stripe
    func createPaymentIntent(amount: Double, currency: String = "cdf") async throws -> String {
        guard let url = URL(string: "\(baseURL)/paiements/create-intent") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "amount": amount,
            "currency": currency
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            throw StripeError.serverError(message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode([String: String].self, from: data)
        
        guard let clientSecret = responseData["clientSecret"] else {
            throw StripeError.serverError(message: "Client secret non trouvé dans la réponse")
        }
        
        return clientSecret
    }
    
    // MARK: - Confirmation de paiement
    
    /// Confirme un paiement pré-autorisé
    func confirmPayment(paymentIntentId: String) async throws -> StripePaymentIntent {
        guard let url = URL(string: "\(baseURL)/paiements/confirm") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "paymentIntentId": paymentIntentId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            throw StripeError.serverError(message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(StripeConfirmResponse.self, from: data)
        
        guard responseData.success else {
            throw StripeError.serverError(message: responseData.error ?? "Erreur inconnue")
        }
        
        return responseData.paymentIntent
    }
}

// MARK: - Modèles Stripe

struct StripePaymentIntent: Codable {
    let id: String
    let clientSecret: String
    let status: String
    let amount: Double
    let currency: String
}

struct StripePreauthorizeResponse: Codable {
    let success: Bool
    let paymentIntent: StripePaymentIntent
    let transaction: StripeTransaction?
    let ride: StripeRide?
    let error: String?
}

struct StripeConfirmResponse: Codable {
    let success: Bool
    let paymentIntent: StripePaymentIntent
    let transaction: StripeTransaction?
    let error: String?
}

struct StripeTransaction: Codable {
    let id: Int
    let rideId: Int?
    let amount: Double
    let status: String
    let createdAt: String
}

struct StripeRide: Codable {
    let id: Int
    let status: String
    let finalPrice: Double?
    let estimatedPrice: Double
}

// MARK: - Erreurs Stripe

enum StripeError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(message: String)
    case invalidToken
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError:
            return "Erreur de connexion réseau"
        case .serverError(let message):
            return message
        case .invalidToken:
            return "Token de paiement invalide"
        case .paymentFailed:
            return "Le paiement a échoué"
        }
    }
}

