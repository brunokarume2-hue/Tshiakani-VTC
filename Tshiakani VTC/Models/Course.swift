//
//  Course.swift
//  Tshiakani VTC
//
//  Modèle correspondant à la table 'courses' du schéma PostgreSQL
//

import Foundation
import CoreLocation

/// Statut de la course
enum StatutCourse: String, Codable {
    case demande = "demandé"
    case accepte = "accepté"
    case annule = "annulé"
    case completed = "completed"
    
    /// Initialise depuis un décodeur
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        
        switch rawValue {
        case "demandé", "demande":
            self = .demande
        case "accepté", "accepte":
            self = .accepte
        case "annulé", "annule":
            self = .annule
        case "completed", "completé":
            self = .completed
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Statut invalide: \(rawValue)"
            )
        }
    }
}

/// Modèle course correspondant à la table 'courses'
struct Course: Identifiable, Decodable {
    /// ID auto-incrémenté (SERIAL PRIMARY KEY)
    let id: Int
    
    /// Référence vers le client (FOREIGN KEY vers utilisateurs(id))
    let client_id: Int
    
    /// Référence vers le chauffeur (FOREIGN KEY vers chauffeurs(id), nullable)
    let chauffeur_id: Int?
    
    /// Point de prise en charge (GEOGRAPHY(Point, 4326) via PostGIS)
    let depart_point: Location
    
    /// Point de destination (GEOGRAPHY(Point, 4326) via PostGIS)
    let arrivee_point: Location
    
    /// Statut de la course
    let statut: StatutCourse
    
    /// Montant estimé de la course (NUMERIC(10, 2))
    let montant_estime: Double
    
    // MARK: - Propriétés calculées
    
    /// Coordonnée du point de départ pour MapKit
    var departCoordinate: CLLocationCoordinate2D {
        depart_point.coordinate
    }
    
    /// Coordonnée du point d'arrivée pour MapKit
    var arriveeCoordinate: CLLocationCoordinate2D {
        arrivee_point.coordinate
    }
    
    /// Vérifie si la course est en attente
    var estEnAttente: Bool {
        statut == .demande
    }
    
    /// Vérifie si la course est acceptée
    var estAcceptee: Bool {
        statut == .accepte
    }
    
    /// Vérifie si la course est terminée
    var estTerminee: Bool {
        statut == .completed
    }
    
    /// Vérifie si la course est annulée
    var estAnnulee: Bool {
        statut == .annule
    }
    
    /// Calcule la distance entre le départ et l'arrivée
    var distance: Double {
        depart_point.distance(to: arrivee_point)
    }
    
    // MARK: - Decodable
    
    /// Structure intermédiaire pour décoder la réponse de l'API PostGIS
    private struct CourseAPIResponse: Decodable {
        let id: Int
        let client_id: Int
        let chauffeur_id: Int?
        let depart_point: LocationPostGIS
        let arrivee_point: LocationPostGIS
        let statut: String
        let montant_estime: Double
        
        /// Structure pour décoder les points géographiques PostGIS
        struct LocationPostGIS: Decodable {
            let type: String
            let coordinates: [Double] // [longitude, latitude] pour PostGIS
            
            /// Convertit en objet Location Swift
            func toLocation() -> Location {
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
    
    /// Initialise une Course depuis la réponse de l'API
    init(from decoder: Decoder) throws {
        let apiResponse = try CourseAPIResponse(from: decoder)
        
        self.id = apiResponse.id
        self.client_id = apiResponse.client_id
        self.chauffeur_id = apiResponse.chauffeur_id
        self.depart_point = apiResponse.depart_point.toLocation()
        self.arrivee_point = apiResponse.arrivee_point.toLocation()
        self.montant_estime = apiResponse.montant_estime
        
        // Valider et convertir le statut
        let statutString = apiResponse.statut.lowercased()
        guard let statutEnum = StatutCourse(rawValue: statutString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Statut invalide: \(apiResponse.statut)"
                )
            )
        }
        self.statut = statutEnum
    }
    
    /// Initialiseur direct pour créer une Course (pour tests)
    init(
        id: Int,
        client_id: Int,
        chauffeur_id: Int? = nil,
        depart_point: Location,
        arrivee_point: Location,
        statut: StatutCourse,
        montant_estime: Double
    ) {
        self.id = id
        self.client_id = client_id
        self.chauffeur_id = chauffeur_id
        self.depart_point = depart_point
        self.arrivee_point = arrivee_point
        self.statut = statut
        self.montant_estime = montant_estime
    }
}

