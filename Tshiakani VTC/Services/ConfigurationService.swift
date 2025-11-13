//
//  ConfigurationService.swift
//  Tshiakani VTC
//
//  Service de configuration centralisé pour l'application
//  Gère les URLs, endpoints, et configurations d'environnement
//

import Foundation

/// Service de configuration centralisé
class ConfigurationService {
    static let shared = ConfigurationService()
    
    // MARK: - URLs de Base
    
    /// URL de base de l'API backend
    var apiBaseURL: String {
        // Vérifier d'abord les variables d'environnement ou UserDefaults (priorité absolue)
        if let customURL = UserDefaults.standard.string(forKey: "api_base_url"), !customURL.isEmpty {
            print("🔧 ConfigurationService: URL depuis UserDefaults: \(customURL)")
            return customURL
        }
        
        // Vérifier Info.plist en priorité (pour Debug et Release)
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            print("🔧 ConfigurationService: URL depuis Info.plist: \(url)")
            return url
        }
        
        // Pour le développement local (seulement si Info.plist n'est pas défini)
        #if DEBUG
        // Détecter si on est sur le simulateur ou un appareil réel
        #if targetEnvironment(simulator)
        // Sur le simulateur, localhost fonctionne directement
        let defaultURL = "http://localhost:3000/api"
        print("⚠️ ConfigurationService: URL par défaut (simulateur DEBUG): \(defaultURL)")
        return defaultURL
        #else
        // Sur un appareil réel, utiliser l'IP locale (à configurer via UserDefaults)
        if let deviceURL = UserDefaults.standard.string(forKey: "api_base_url_device"), !deviceURL.isEmpty {
            print("🔧 ConfigurationService: URL depuis UserDefaults (device): \(deviceURL)")
            return deviceURL
        }
        // Fallback vers Cloud Run même en DEBUG si aucune configuration locale
        let cloudRunURL = "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"
        print("⚠️ ConfigurationService: URL par défaut (appareil réel DEBUG): \(cloudRunURL)")
        return cloudRunURL
        #endif
        #else
        // Pour la production, fallback vers Cloud Run centralisé
        let productionURL = "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"
        print("🔧 ConfigurationService: URL production: \(productionURL)")
        return productionURL
        #endif
    }
    
    /// URL de base du serveur WebSocket/Socket.io
    var socketBaseURL: String {
        // Vérifier d'abord UserDefaults (priorité absolue)
        if let customURL = UserDefaults.standard.string(forKey: "socket_base_url"), !customURL.isEmpty {
            return customURL
        }
        
        // Vérifier Info.plist en priorité (pour Debug et Release)
        if let url = Bundle.main.object(forInfoDictionaryKey: "WS_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        
        #if DEBUG
        // Détecter si on est sur le simulateur ou un appareil réel
        #if targetEnvironment(simulator)
        // Sur le simulateur, localhost fonctionne directement
        return "http://localhost:3000"
        #else
        // Sur un appareil réel, utiliser l'IP locale
        if let deviceURL = UserDefaults.standard.string(forKey: "socket_base_url_device"), !deviceURL.isEmpty {
            return deviceURL
        }
        // Fallback vers Cloud Run même en DEBUG si aucune configuration locale
        return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
        #endif
        #else
        // Pour la production, fallback vers Cloud Run centralisé
        return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
        #endif
    }
    
    /// URL du namespace WebSocket pour les drivers
    var driverSocketNamespace: String {
        return "/ws/driver"
    }
    
    /// URL du namespace WebSocket pour les clients
    var clientSocketNamespace: String {
        return "/ws/client"
    }
    
    // MARK: - Endpoints API
    
    struct Endpoints {
        // Authentification
        static let authSignin = "/auth/signin"
        static let authSignup = "/auth/signup"
        static let authVerify = "/auth/verify"
        static let authProfile = "/auth/profile"
        
        // Courses
        static let ridesCreate = "/rides/create"
        static let ridesEstimatePrice = "/rides/estimate-price"
        static let ridesHistory = "/rides/history"
        static let ridesStatus = "/rides/{id}/status"
        static let ridesRate = "/rides/{id}/rate"
        static let ridesDetail = "/rides/{id}"
        
        // Client
        static let clientTrackDriver = "/client/track_driver/{rideId}"
        
        // Location
        static let locationDriversNearby = "/location/drivers/nearby"
        static let locationUpdate = "/location/update"
        
        // Paiements
        static let paymentsPreauthorize = "/paiements/preauthorize"
        static let paymentsConfirm = "/paiements/confirm"
        
        // Utilisateurs
        static let users = "/users"
        static let usersProfile = "/users/{id}/profile"
        
        // Notifications
        static let notifications = "/notifications"
        
        // SOS
        static let sos = "/sos"
        static let sosReport = "/sos/report"
        
        // Admin
        static let adminStats = "/admin/stats"
        static let adminRides = "/admin/rides"
        static let adminUsers = "/admin/users"
    }
    
    // MARK: - Configuration WebSocket
    
    /// Timeout pour la connexion WebSocket (en secondes)
    var socketConnectionTimeout: TimeInterval {
        return 10.0
    }
    
    /// Intervalle de reconnexion automatique (en secondes)
    var socketReconnectInterval: TimeInterval {
        return 5.0
    }
    
    /// Nombre maximum de tentatives de reconnexion
    var socketMaxReconnectAttempts: Int {
        return 5
    }
    
    /// Intervalle pour le ping/pong (keep-alive) en secondes
    var socketPingInterval: TimeInterval {
        return 30.0
    }
    
    // MARK: - Configuration API
    
    /// Timeout pour les requêtes HTTP (en secondes)
    var httpTimeout: TimeInterval {
        return 30.0
    }
    
    /// Nombre maximum de tentatives de retry pour les requêtes HTTP
    var httpMaxRetries: Int {
        return 3
    }
    
    // MARK: - Clés de stockage
    
    struct StorageKeys {
        static let authToken = "auth_token"
        static let userId = "user_id"
        static let userRole = "user_role"
        static let apiBaseURL = "api_base_url"
        static let socketBaseURL = "socket_base_url"
        static let fcmToken = "fcm_token"
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Construit une URL complète pour un endpoint
    func buildURL(for endpoint: String, parameters: [String: String] = [:]) -> String {
        var url = "\(apiBaseURL)\(endpoint)"
        
        // Remplacer les paramètres dans l'URL
        for (key, value) in parameters {
            url = url.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        return url
    }
    
    /// Construit une URL WebSocket complète
    func buildSocketURL(namespace: String? = nil) -> String {
        var url = socketBaseURL
        if let namespace = namespace {
            url = "\(url)\(namespace)"
        }
        return url
    }
    
    /// Récupère le token d'authentification
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: StorageKeys.authToken)
    }
    
    /// Définit le token d'authentification
    func setAuthToken(_ token: String?) {
        if let token = token {
            UserDefaults.standard.set(token, forKey: StorageKeys.authToken)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.authToken)
        }
    }
    
    /// Récupère l'ID de l'utilisateur actuel
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: StorageKeys.userId)
    }
    
    /// Définit l'ID de l'utilisateur actuel
    func setUserId(_ userId: String?) {
        if let userId = userId {
            UserDefaults.standard.set(userId, forKey: StorageKeys.userId)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.userId)
        }
    }
    
    /// Récupère le rôle de l'utilisateur actuel
    func getUserRole() -> UserRole? {
        guard let roleString = UserDefaults.standard.string(forKey: StorageKeys.userRole) else {
            return nil
        }
        return UserRole(rawValue: roleString)
    }
    
    /// Définit le rôle de l'utilisateur actuel
    func setUserRole(_ role: UserRole?) {
        if let role = role {
            UserDefaults.standard.set(role.rawValue, forKey: StorageKeys.userRole)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.userRole)
        }
    }
    
    private init() {}
}

