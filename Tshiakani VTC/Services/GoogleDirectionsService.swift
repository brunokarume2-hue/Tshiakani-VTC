//
//  GoogleDirectionsService.swift
//  Tshiakani VTC
//
//  Service pour calculer les itinéraires avec Google Directions API
//

import Foundation
import CoreLocation

/// Résultat du calcul d'itinéraire
struct RouteResult {
    let distance: Double // en kilomètres
    let duration: Int // en secondes
    let durationInTraffic: Int? // en secondes (avec trafic)
    let polyline: String // Encodage polyline pour tracer la route
    let steps: [RouteStep] // Étapes détaillées du trajet
}

/// Étape d'un itinéraire
struct RouteStep {
    let distance: Double // en mètres
    let duration: Int // en secondes
    let instruction: String
    let polyline: String
}

/// Informations d'estimation de prix basées sur l'itinéraire
struct PriceEstimateFromRoute {
    let distance: Double // km
    let duration: Int // minutes
    let estimatedPrice: Double // CDF
}

class GoogleDirectionsService {
    static let shared = GoogleDirectionsService()
    
    private var apiKey: String {
        // Récupérer la clé API depuis Info.plist ou variables d'environnement
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
           !key.isEmpty {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"],
           !key.isEmpty {
            return key
        }
        return ""
    }
    
    private let baseURL = "https://maps.googleapis.com/maps/api/directions/json"
    
    private init() {}
    
    /// Calcule l'itinéraire entre deux points
    /// - Parameters:
    ///   - origin: Point de départ
    ///   - destination: Point d'arrivée
    ///   - mode: Mode de transport (driving par défaut)
    /// - Returns: RouteResult avec distance, durée et polyline
    func calculateRoute(
        from origin: Location,
        to destination: Location,
        mode: String = "driving"
    ) async throws -> RouteResult {
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Clé API Google Maps non configurée"]
            )
        }
        
        let originStr = "\(origin.latitude),\(origin.longitude)"
        let destStr = "\(destination.latitude),\(destination.longitude)"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "origin", value: originStr),
            URLQueryItem(name: "destination", value: destStr),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "language", value: "fr"),
            URLQueryItem(name: "region", value: "cd"), // République Démocratique du Congo
            URLQueryItem(name: "departure_time", value: "now"), // Pour obtenir le trafic en temps réel
            URLQueryItem(name: "alternatives", value: "false") // Une seule route
        ]
        
        guard let url = components.url else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "URL invalide"]
            )
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Erreur HTTP"]
            )
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json,
              let routes = json["routes"] as? [[String: Any]],
              let firstRoute = routes.first,
              let legs = firstRoute["legs"] as? [[String: Any]],
              let firstLeg = legs.first else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Aucun itinéraire trouvé"]
            )
        }
        
        // Distance totale
        guard let distanceDict = firstLeg["distance"] as? [String: Any],
              let distanceValue = distanceDict["value"] as? Int else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Distance non trouvée"]
            )
        }
        let distanceKm = Double(distanceValue) / 1000.0
        
        // Durée totale
        guard let durationDict = firstLeg["duration"] as? [String: Any],
              let durationValue = durationDict["value"] as? Int else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Durée non trouvée"]
            )
        }
        
        // Durée avec trafic (si disponible)
        var durationInTraffic: Int? = nil
        if let durationInTrafficDict = firstLeg["duration_in_traffic"] as? [String: Any],
           let durationInTrafficValue = durationInTrafficDict["value"] as? Int {
            durationInTraffic = durationInTrafficValue
        }
        
        // Polyline pour tracer la route
        guard let overviewPolyline = firstRoute["overview_polyline"] as? [String: Any],
              let polyline = overviewPolyline["points"] as? String else {
            throw NSError(
                domain: "GoogleDirectionsService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Polyline non trouvée"]
            )
        }
        
        // Étapes détaillées
        var steps: [RouteStep] = []
        if let stepsArray = firstLeg["steps"] as? [[String: Any]] {
            steps = stepsArray.compactMap { stepDict in
                guard let stepDistance = stepDict["distance"] as? [String: Any],
                      let stepDistanceValue = stepDistance["value"] as? Int,
                      let stepDuration = stepDict["duration"] as? [String: Any],
                      let stepDurationValue = stepDuration["value"] as? Int,
                      let stepPolyline = stepDict["polyline"] as? [String: Any],
                      let stepPolylinePoints = stepPolyline["points"] as? String,
                      let htmlInstruction = stepDict["html_instructions"] as? String else {
                    return nil
                }
                
                // Nettoyer les instructions HTML
                let instruction = htmlInstruction
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                return RouteStep(
                    distance: Double(stepDistanceValue),
                    duration: stepDurationValue,
                    instruction: instruction,
                    polyline: stepPolylinePoints
                )
            }
        }
        
        return RouteResult(
            distance: distanceKm,
            duration: durationValue,
            durationInTraffic: durationInTraffic,
            polyline: polyline,
            steps: steps
        )
    }
    
    /// Calcule l'estimation de prix basée sur l'itinéraire
    /// - Parameters:
    ///   - origin: Point de départ
    ///   - destination: Point d'arrivée
    /// - Returns: PriceEstimateFromRoute avec distance, durée et prix estimé
    func estimatePrice(
        from origin: Location,
        to destination: Location
    ) async throws -> PriceEstimateFromRoute {
        let route = try await calculateRoute(from: origin, to: destination)
        
        // Utiliser la durée avec trafic si disponible, sinon la durée normale
        let durationMinutes = (route.durationInTraffic ?? route.duration) / 60
        
        // Calcul du prix basé sur la distance et le temps
        // Tarif de base: 500 CDF + 200 CDF par km + 50 CDF par minute
        let basePrice = 500.0
        let pricePerKm = 200.0
        let pricePerMinute = 50.0
        
        let estimatedPrice = basePrice + (route.distance * pricePerKm) + (Double(durationMinutes) * pricePerMinute)
        
        return PriceEstimateFromRoute(
            distance: route.distance,
            duration: durationMinutes,
            estimatedPrice: estimatedPrice
        )
    }
}

