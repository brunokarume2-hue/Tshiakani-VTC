//
//  Chauffeur.swift
//  Tshiakani VTC
//
//  Modèle correspondant à la table 'chauffeurs' du schéma PostgreSQL
//

import Foundation
import CoreLocation

/// Statut du chauffeur pour l'algorithme d'allocation
enum StatutChauffeur: String, Codable {
    case disponible = "disponible"
    case en_course = "en_course"
    case hors_ligne = "hors_ligne"
    
    /// Initialise depuis un décodeur
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        
        switch rawValue {
        case "disponible":
            self = .disponible
        case "en_course":
            self = .en_course
        case "hors_ligne":
            self = .hors_ligne
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Statut invalide: \(rawValue). Doit être 'disponible', 'en_course' ou 'hors_ligne'"
            )
        }
    }
}

/// Modèle chauffeur correspondant à la table 'chauffeurs'
struct Chauffeur: Identifiable, Decodable {
    /// ID auto-incrémenté (SERIAL PRIMARY KEY)
    let id: Int
    
    /// Référence vers l'utilisateur (FOREIGN KEY vers utilisateurs(id))
    let user_id: Int
    
    /// Localisation en temps réel (GEOGRAPHY(Point, 4326) via PostGIS)
    let localisation: Location
    
    /// Statut pour l'algorithme d'allocation (CHECK: 'disponible', 'en_course', 'hors_ligne')
    let statut: StatutChauffeur
    
    // MARK: - Propriétés calculées
    
    /// Coordonnée CLLocationCoordinate2D pour MapKit
    var coordinate: CLLocationCoordinate2D {
        localisation.coordinate
    }
    
    /// Vérifie si le chauffeur est disponible
    var estDisponible: Bool {
        statut == .disponible
    }
    
    /// Vérifie si le chauffeur est en course
    var estEnCourse: Bool {
        statut == .en_course
    }
    
    // MARK: - Decodable
    
    /// Structure intermédiaire pour décoder la réponse de l'API PostGIS
    private struct ChauffeurAPIResponse: Decodable {
        let id: Int
        let user_id: Int
        let localisation: LocationPostGIS
        let statut: String
        
        /// Structure pour décoder la localisation PostGIS
        struct LocationPostGIS: Decodable {
            let type: String
            let coordinates: [Double] // [longitude, latitude] pour PostGIS
            
            /// Convertit en objet Location Swift
            func toLocation() -> Location {
                // PostGIS utilise [longitude, latitude]
                let longitude = coordinates[0]
                let latitude = coordinates[1]
                
                return Location(
                    latitude: latitude,
                    longitude: longitude,
                    timestamp: Date()
                )
            }
        }
    }
    
    /// Initialise un Chauffeur depuis la réponse de l'API
    init(from decoder: Decoder) throws {
        let apiResponse = try ChauffeurAPIResponse(from: decoder)
        
        self.id = apiResponse.id
        self.user_id = apiResponse.user_id
        self.localisation = apiResponse.localisation.toLocation()
        
        // Valider et convertir le statut
        let statutString = apiResponse.statut.lowercased()
        guard let statutEnum = StatutChauffeur(rawValue: statutString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Statut invalide: \(apiResponse.statut)"
                )
            )
        }
        self.statut = statutEnum
    }
    
    /// Initialiseur direct pour créer un Chauffeur (pour tests)
    init(id: Int, user_id: Int, localisation: Location, statut: StatutChauffeur) {
        self.id = id
        self.user_id = user_id
        self.localisation = localisation
        self.statut = statut
    }
}

