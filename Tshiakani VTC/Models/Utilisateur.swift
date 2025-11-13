//
//  Utilisateur.swift
//  Tshiakani VTC
//
//  Modèle correspondant à la table 'utilisateurs' du schéma PostgreSQL
//

import Foundation

/// Rôle de l'utilisateur dans le système
enum RoleUtilisateur: String, Codable {
    case client = "client"
    case chauffeur = "chauffeur"
    
    /// Convertit depuis les valeurs possibles de la base de données
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        
        switch rawValue {
        case "client":
            self = .client
        case "chauffeur":
            self = .chauffeur
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Rôle invalide: \(rawValue). Doit être 'client' ou 'chauffeur'"
            )
        }
    }
}

/// Modèle utilisateur correspondant à la table 'utilisateurs'
struct Utilisateur: Identifiable, Decodable {
    /// ID auto-incrémenté (SERIAL PRIMARY KEY)
    let id: Int
    
    /// Rôle de l'utilisateur (CHECK: 'client' ou 'chauffeur')
    let role: RoleUtilisateur
    
    /// Email unique pour l'identification
    let email: String
    
    /// Hash du mot de passe (non décodé depuis l'API pour sécurité)
    let password_hash: String?
    
    // MARK: - Propriétés calculées
    
    /// Vérifie si l'utilisateur est un client
    var estClient: Bool {
        role == .client
    }
    
    /// Vérifie si l'utilisateur est un chauffeur
    var estChauffeur: Bool {
        role == .chauffeur
    }
    
    // MARK: - Decodable
    
    /// Structure intermédiaire pour décoder la réponse de l'API
    private struct UtilisateurAPIResponse: Decodable {
        let id: Int
        let role: String
        let email: String
        let password_hash: String?
    }
    
    /// Initialise un Utilisateur depuis la réponse de l'API
    init(from decoder: Decoder) throws {
        let apiResponse = try UtilisateurAPIResponse(from: decoder)
        
        self.id = apiResponse.id
        self.email = apiResponse.email
        self.password_hash = apiResponse.password_hash
        
        // Valider et convertir le rôle
        let roleString = apiResponse.role.lowercased()
        guard let roleEnum = RoleUtilisateur(rawValue: roleString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Rôle invalide: \(apiResponse.role). Doit être 'client' ou 'chauffeur'"
                )
            )
        }
        self.role = roleEnum
    }
    
    /// Initialiseur direct pour créer un Utilisateur (pour tests)
    init(id: Int, role: RoleUtilisateur, email: String, password_hash: String? = nil) {
        self.id = id
        self.role = role
        self.email = email
        self.password_hash = password_hash
    }
}

