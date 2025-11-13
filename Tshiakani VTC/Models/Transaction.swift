//
//  Transaction.swift
//  Tshiakani VTC
//
//  Modèle correspondant à la table 'transactions' du schéma PostgreSQL
//

import Foundation

/// Statut de la transaction de paiement
enum StatutTransaction: String, Codable {
    case charged = "charged"    // Paiement effectué
    case failed = "failed"     // Paiement échoué
    case refunded = "refunded" // Paiement remboursé
    
    /// Initialise depuis un décodeur
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        
        switch rawValue {
        case "charged":
            self = .charged
        case "failed":
            self = .failed
        case "refunded":
            self = .refunded
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Statut invalide: \(rawValue). Doit être 'charged', 'failed' ou 'refunded'"
            )
        }
    }
}

/// Modèle transaction correspondant à la table 'transactions'
struct Transaction: Identifiable, Decodable {
    /// ID auto-incrémenté (SERIAL PRIMARY KEY)
    let id: Int
    
    /// Référence vers la course (FOREIGN KEY vers courses(id), UNIQUE - relation 1:1)
    let course_id: Int
    
    /// Montant final de la transaction (NUMERIC(10, 2))
    let montant_final: Double
    
    /// Token de paiement du prestataire (Stripe, etc.)
    let token_paiement: String
    
    /// Statut final du paiement (CHECK: 'charged', 'failed', 'refunded')
    let statut: StatutTransaction
    
    // MARK: - Propriétés calculées
    
    /// Vérifie si le paiement a été effectué avec succès
    var estPaye: Bool {
        statut == .charged
    }
    
    /// Vérifie si le paiement a échoué
    var aEchoue: Bool {
        statut == .failed
    }
    
    /// Vérifie si le paiement a été remboursé
    var estRembourse: Bool {
        statut == .refunded
    }
    
    /// Montant formaté pour l'affichage
    var montantFormate: String {
        String(format: "%.2f", montant_final)
    }
    
    // MARK: - Decodable
    
    /// Structure intermédiaire pour décoder la réponse de l'API
    private struct TransactionAPIResponse: Decodable {
        let id: Int
        let course_id: Int
        let montant_final: Double
        let token_paiement: String
        let statut: String
    }
    
    /// Initialise une Transaction depuis la réponse de l'API
    init(from decoder: Decoder) throws {
        let apiResponse = try TransactionAPIResponse(from: decoder)
        
        self.id = apiResponse.id
        self.course_id = apiResponse.course_id
        self.montant_final = apiResponse.montant_final
        self.token_paiement = apiResponse.token_paiement
        
        // Valider et convertir le statut
        let statutString = apiResponse.statut.lowercased()
        guard let statutEnum = StatutTransaction(rawValue: statutString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Statut invalide: \(apiResponse.statut). Doit être 'charged', 'failed' ou 'refunded'"
                )
            )
        }
        self.statut = statutEnum
    }
    
    /// Initialiseur direct pour créer une Transaction (pour tests)
    init(
        id: Int,
        course_id: Int,
        montant_final: Double,
        token_paiement: String,
        statut: StatutTransaction
    ) {
        self.id = id
        self.course_id = course_id
        self.montant_final = montant_final
        self.token_paiement = token_paiement
        self.statut = statut
    }
}

