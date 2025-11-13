//
//  APIService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import Combine

// Types de réponse globaux pour éviter les déclarations en double
private struct LocationResponse: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let timestamp: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil, timestamp: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.timestamp = timestamp
    }
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let firebaseService = FirebaseService.shared
    private let localStorage = LocalStorageService.shared
    private let config = ConfigurationService.shared
    private let dataTransform = DataTransformService.shared
    
    private var baseURL: String {
        return config.apiBaseURL
    }
    
    private init() {}
    
    // MARK: - HTTP Methods
    
    /// Méthode POST générique pour communiquer avec le backend Node.js
    func post(endpoint: String, body: [String: Any]) async throws {
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 APIService POST: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ APIService: URL invalide - \(fullURL)")
            throw APIError(type: .validation, message: "URL invalide: \(fullURL)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        
        // Ajouter le token JWT si disponible
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 APIService: Token JWT ajouté")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            print("📤 APIService: Envoi de la requête...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ APIService: Réponse invalide")
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            print("📥 APIService: Réponse reçue - Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Essayer de décoder le message d'erreur du serveur
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
                
                print("❌ APIService: Erreur HTTP \(httpResponse.statusCode) - \(message)")
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode == 404 ? .notFound :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            print("✅ APIService: Requête réussie")
        } catch let error as APIError {
            print("❌ APIService: Erreur API - \(error.type) - \(error.message ?? "Pas de message")")
            throw error
        } catch {
            print("❌ APIService: Erreur réseau - \(error.localizedDescription)")
            let apiError = APIError.from(error)
            print("❌ APIService: Erreur convertie - \(apiError.type) - \(apiError.message ?? "Pas de message")")
            throw apiError
        }
    }
    
    /// Méthode GET générique pour communiquer avec le backend Node.js
    func get<T: Decodable>(endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)")
        
        if let queryItems = queryItems {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        
        // Ajouter le token JWT si disponible
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Essayer de décoder le message d'erreur du serveur
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode == 404 ? .notFound :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    // MARK: - Authentication
    
    /// Envoie un code OTP au numéro de téléphone
    func sendOTP(phoneNumber: String, channel: String = "whatsapp") async throws -> (channel: String, expiresIn: Int, code: String?) {
        struct Response: Codable {
            let success: Bool
            let message: String?
            let channel: String
            let expiresIn: Int
            let code: String? // Seulement en développement
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "channel": channel
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/send-otp") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de l'envoi du code OTP"
                
                throw APIError(
                    type: httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            let responseData = try decoder.decode(Response.self, from: data)
            
            return (channel: responseData.channel, expiresIn: responseData.expiresIn, code: responseData.code)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Inscription avec mot de passe
    func register(phoneNumber: String, name: String, password: String, role: UserRole = .client) async throws -> (token: String, user: User) {
        struct Request: Codable {
            let phoneNumber: String
            let name: String
            let password: String
            let role: String
        }
        
        struct Response: Codable {
            let success: Bool
            let token: String
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let isVerified: Bool
        }
        
        print("📝 APIService.register: Début de l'inscription")
        print("📝 APIService.register: baseURL = \(baseURL)")
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "name": name,
            "password": password,
            "role": role.rawValue
        ]
        
        let endpoint = "/auth/register"
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 APIService.register: URL complète = \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ APIService.register: URL invalide - \(fullURL)")
            throw APIError(type: .validation, message: "URL invalide: \(fullURL)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 APIService.register: Envoi de la requête d'inscription...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ APIService.register: Réponse invalide")
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            print("📥 APIService.register: Réponse reçue - Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de l'inscription"
                
                print("❌ APIService.register: Erreur HTTP \(httpResponse.statusCode) - \(message)")
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation : 
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            print("✅ APIService.register: Inscription réussie - User ID: \(responseData.user.id)")
            
            let user = User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber,
                email: nil,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                createdAt: Date(),
                isVerified: responseData.user.isVerified
            )
            
            return (token: responseData.token, user: user)
        } catch let error as APIError {
            print("❌ APIService.register: Erreur API - \(error.type) - \(error.message ?? "Pas de message")")
            throw error
        } catch {
            print("❌ APIService.register: Erreur réseau - \(error.localizedDescription)")
            print("❌ APIService.register: Type d'erreur - \(type(of: error))")
            if let nsError = error as NSError? {
                print("❌ APIService.register: Domain - \(nsError.domain), Code - \(nsError.code)")
                print("❌ APIService.register: UserInfo - \(nsError.userInfo)")
            }
            let apiError = APIError.from(error)
            print("❌ APIService.register: Erreur convertie - \(apiError.type) - \(apiError.message ?? "Pas de message")")
            throw apiError
        }
    }
    
    /// Connexion avec mot de passe
    func login(phoneNumber: String, password: String) async throws -> (token: String, user: User) {
        struct Request: Codable {
            let phoneNumber: String
            let password: String
        }
        
        struct Response: Codable {
            let success: Bool
            let token: String
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let isVerified: Bool
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "password": password
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la connexion"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation : 
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            let user = User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber,
                email: nil,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                createdAt: Date(),
                isVerified: responseData.user.isVerified
            )
            
            return (token: responseData.token, user: user)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Demande de réinitialisation de mot de passe (envoie un code OTP)
    func forgotPassword(phoneNumber: String) async throws {
        struct Response: Codable {
            let success: Bool
            let message: String?
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la demande de réinitialisation"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation :
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Réinitialise le mot de passe avec un code OTP
    func resetPassword(phoneNumber: String, code: String, newPassword: String) async throws {
        struct Response: Codable {
            let success: Bool
            let message: String?
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code,
            "newPassword": newPassword
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/reset-password") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la réinitialisation"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation :
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Change le mot de passe (nécessite authentification)
    func changePassword(currentPassword: String, newPassword: String) async throws {
        struct Response: Codable {
            let success: Bool
            let message: String?
        }
        
        let body: [String: Any] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/change-password") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        
        // Ajouter le token JWT
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError(type: .authentication, message: "Authentification requise")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors du changement de mot de passe"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation :
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Définit un mot de passe pour les utilisateurs existants sans mot de passe
    func setPassword(phoneNumber: String, code: String, password: String) async throws -> (token: String, user: User) {
        struct Response: Codable {
            let success: Bool
            let token: String?
            let message: String?
            let user: UserResponse?
        }
        
        struct UserResponse: Codable {
            let id: Int
            let phoneNumber: String
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code,
            "password": password
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/set-password") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la définition du mot de passe"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation :
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            guard let token = responseData.token, let userResponse = responseData.user else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            let user = User(
                id: String(userResponse.id),
                name: "",
                phoneNumber: userResponse.phoneNumber,
                email: nil,
                role: .client,
                createdAt: Date(),
                isVerified: true
            )
            
            return (token: token, user: user)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Vérifie le code OTP et authentifie l'utilisateur (ancienne méthode - gardée pour compatibilité)
    func verifyOTP(phoneNumber: String, code: String, role: UserRole, name: String? = nil) async throws -> (token: String, user: User) {
        struct Request: Codable {
            let phoneNumber: String
            let code: String
            let role: String
            let name: String?
        }
        
        struct Response: Codable {
            let success: Bool
            let token: String
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let isVerified: Bool
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code,
            "role": role.rawValue,
            "name": name as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/verify-otp") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Code OTP invalide"
                
                throw APIError(
                    type: httpResponse.statusCode == 400 ? .validation : 
                          httpResponse.statusCode >= 500 ? .server : .authentication,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            // Convertir la réponse en modèle User
            let user = User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber,
                email: nil,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                createdAt: Date(),
                isVerified: responseData.user.isVerified
            )
            
            return (token: responseData.token, user: user)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Authentifie un utilisateur via l'API backend (/auth/signin)
    func signIn(phoneNumber: String, role: UserRole, name: String? = nil) async throws -> (token: String, user: User) {
        struct Request: Codable {
            let phoneNumber: String
            let role: String
            let name: String?
        }
        
        struct Response: Codable {
            let token: String
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let isVerified: Bool
        }
        
        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "role": role.rawValue,
            "name": name as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/signin") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la connexion"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            // Convertir la réponse en modèle User
            let user = User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber,
                email: nil,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                createdAt: Date(),
                isVerified: responseData.user.isVerified
            )
            
            return (token: responseData.token, user: user)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Authentifie un utilisateur via Google Sign-In
    func signInWithGoogle(idToken: String, email: String, name: String, photoURL: String? = nil) async throws -> (token: String, user: User) {
        struct Request: Codable {
            let idToken: String
            let email: String
            let name: String
            let photoURL: String?
        }
        
        struct Response: Codable {
            let token: String
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String?
            let email: String?
            let role: String
            let isVerified: Bool
        }
        
        let body: [String: Any] = [
            "idToken": idToken,
            "email": email,
            "name": name,
            "photoURL": photoURL as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/auth/google") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la connexion Google"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            // Convertir la réponse en modèle User
            let user = User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber ?? "",
                email: responseData.user.email,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                createdAt: Date(),
                isVerified: responseData.user.isVerified
            )
            
            return (token: responseData.token, user: user)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    // MARK: - Users
    
    /// Crée un utilisateur via l'API backend
    func createUser(_ user: User) async throws -> User {
        struct Request: Codable {
            let name: String
            let phoneNumber: String
            let role: String
            let email: String?
        }
        
        struct Response: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let email: String?
            let role: String
            let isVerified: Bool
            let createdAt: String
        }
        
        let body: [String: Any] = [
            "name": user.name,
            "phoneNumber": user.phoneNumber,
            "role": user.role.rawValue,
            "email": user.email as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/users") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la création de l'utilisateur"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            return User(
                id: String(responseData.id),
                name: responseData.name,
                phoneNumber: responseData.phoneNumber,
                email: responseData.email,
                role: UserRole(rawValue: responseData.role) ?? .client,
                createdAt: ISO8601DateFormatter().date(from: responseData.createdAt) ?? Date(),
                isVerified: responseData.isVerified
            )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    /// Récupère le profil utilisateur actuel depuis l'API (via /auth/verify)
    func getUserProfile() async throws -> User {
        struct Response: Codable {
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let isVerified: Bool
        }
        
        print("📥 APIService.getUserProfile: Récupération du profil utilisateur...")
        
        let responseData: Response = try await get(endpoint: "/auth/verify")
        
        print("✅ APIService.getUserProfile: Profil récupéré - User ID: \(responseData.user.id)")
        
        return User(
            id: String(responseData.user.id),
            name: responseData.user.name,
            phoneNumber: responseData.user.phoneNumber,
            email: nil,
            role: UserRole(rawValue: responseData.user.role) ?? .client,
            createdAt: Date(),
            isVerified: responseData.user.isVerified
        )
    }
    
    /// Récupère un utilisateur via l'API backend
    func getUser(id: String) async throws -> User {
        struct Response: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let email: String?
            let role: String
            let isVerified: Bool
            let createdAt: String
        }
        
        let responseData: Response = try await get(endpoint: "/users/\(id)")
        
        return User(
            id: String(responseData.id),
            name: responseData.name,
            phoneNumber: responseData.phoneNumber,
            email: responseData.email,
            role: UserRole(rawValue: responseData.role) ?? .client,
            createdAt: ISO8601DateFormatter().date(from: responseData.createdAt) ?? Date(),
            isVerified: responseData.isVerified
        )
    }
    
    /// Met à jour le profil utilisateur via l'API backend
    func updateProfile(name: String, profileImageURL: String? = nil) async throws -> User {
        struct Response: Codable {
            let user: UserResponse
        }
        
        struct UserResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let role: String
            let profileImageURL: String?
        }
        
        guard let url = URL(string: "\(baseURL)/auth/profile") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.httpTimeout
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = ["name": name]
        if let profileImageURL = profileImageURL {
            body["profileImageURL"] = profileImageURL
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de la mise à jour du profil"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            // Construire l'utilisateur depuis la réponse
            return User(
                id: String(responseData.user.id),
                name: responseData.user.name,
                phoneNumber: responseData.user.phoneNumber,
                email: nil,
                role: UserRole(rawValue: responseData.user.role) ?? .client,
                profileImageURL: responseData.user.profileImageURL,
                createdAt: Date(),
                isVerified: false
            )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    // MARK: - Rides
    
    // MARK: - Pricing
    
    /// Calcule le prix estimé avec l'algorithme IA
    func estimatePrice(pickup: Location, dropoff: Location, distance: Double? = nil) async throws -> PriceEstimate {
        struct Request: Codable {
            let pickupLocation: Location
            let dropoffLocation: Location
            let distance: Double?
        }
        
        struct Response: Codable {
            let price: Double
            let basePrice: Double
            let distance: Double
            let explanation: String
            let multipliers: Multipliers
            let breakdown: PriceBreakdown
        }
        
        struct Multipliers: Codable {
            let time: Double
            let day: Double
            let surge: Double
        }
        
        struct PriceBreakdown: Codable {
            let base: Double
            let distance: Double
            let timeAdjustment: Double
            let dayAdjustment: Double
            let surgeAdjustment: Double
        }
        
        let body: [String: Any] = [
            "pickupLocation": [
                "latitude": pickup.latitude,
                "longitude": pickup.longitude,
                "address": pickup.address ?? ""
            ],
            "dropoffLocation": [
                "latitude": dropoff.latitude,
                "longitude": dropoff.longitude,
                "address": dropoff.address ?? ""
            ],
            "distance": distance as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/rides/estimate-price") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de l'estimation du prix"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode == 404 ? .notFound :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
        
        return PriceEstimate(
            price: responseData.price,
            basePrice: responseData.basePrice,
            distance: responseData.distance,
            explanation: responseData.explanation,
            multipliers: PriceMultipliers(
                time: responseData.multipliers.time,
                day: responseData.multipliers.day,
                surge: responseData.multipliers.surge
            ),
            breakdown: PriceBreakdownData(
                base: responseData.breakdown.base,
                distance: responseData.breakdown.distance,
                timeAdjustment: responseData.breakdown.timeAdjustment,
                dayAdjustment: responseData.breakdown.dayAdjustment,
                surgeAdjustment: responseData.breakdown.surgeAdjustment
            )
        )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    func createRide(_ ride: Ride) async throws -> Ride {
        // 🧠 Utiliser le backend API avec pricing IA et matching automatique
        struct Request: Codable {
            let pickupLocation: LocationRequest
            let dropoffLocation: LocationRequest
            let distance: Double?
        }
        
        struct LocationRequest: Codable {
            let latitude: Double
            let longitude: Double
            let address: String?
        }
        
        struct Response: Codable {
            let id: Int
            let clientId: Int
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let pickupAddress: String?
            let dropoffAddress: String?
            let status: String
            let estimatedPrice: Double
            let finalPrice: Double?
            let distance: Double?
            let createdAt: String
            let pricing: PricingResponse?
        }
        
        
        struct PricingResponse: Codable {
            let finalPrice: Double
            let basePrice: Double
            let explanation: String
        }
        
        let body: [String: Any] = [
            "pickupLocation": [
                "latitude": ride.pickupLocation.latitude,
                "longitude": ride.pickupLocation.longitude,
                "address": ride.pickupLocation.address ?? ""
            ],
            "dropoffLocation": [
                "latitude": ride.dropoffLocation.latitude,
                "longitude": ride.dropoffLocation.longitude,
                "address": ride.dropoffLocation.address ?? ""
            ],
            "distance": ride.distance ?? 0.0
        ]
        
        guard let url = URL(string: "\(baseURL)/rides/create") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["error"] as? String ?? errorData?["message"] as? String ?? "Erreur lors de la création de la course"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode == 404 ? .notFound :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: errorMessage,
                    statusCode: httpResponse.statusCode
                )
            }
        
            // Utiliser DataTransformService pour convertir la réponse si disponible
            if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let createdRide = dataTransform.rideFromBackend(responseData) {
                return createdRide
            }
            
            // Fallback: décodage manuel si la transformation échoue
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            // Convertir la réponse backend en modèle Ride iOS
            let createdRide = Ride(
                id: String(responseData.id),
                clientId: String(responseData.clientId),
                pickupLocation: Location(
                    latitude: responseData.pickupLocation.latitude,
                    longitude: responseData.pickupLocation.longitude,
                    address: responseData.pickupAddress
                ),
                dropoffLocation: Location(
                    latitude: responseData.dropoffLocation.latitude,
                    longitude: responseData.dropoffLocation.longitude,
                    address: responseData.dropoffAddress
                ),
                status: RideStatus(rawValue: responseData.status) ?? .pending,
                estimatedPrice: responseData.estimatedPrice,
                finalPrice: responseData.finalPrice,
                distance: responseData.distance,
                createdAt: ISO8601DateFormatter().date(from: responseData.createdAt) ?? Date()
            )
            
            return createdRide
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    func updateRideStatus(_ rideId: String, status: RideStatus) async throws -> Ride {
        struct Request: Codable {
            let status: String
        }
        
        struct Response: Codable {
            let id: Int
            let clientId: Int
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let pickupAddress: String?
            let dropoffAddress: String?
            let status: String
            let estimatedPrice: Double
            let finalPrice: Double?
            let distance: Double?
            let createdAt: String
        }
        
        
        let body: [String: Any] = [
            "status": status.rawValue
        ]
        
        guard let url = URL(string: "\(baseURL)/rides/\(rideId)/status") else {
            throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "APIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseData = try decoder.decode(Response.self, from: data)
        
        return Ride(
            id: String(responseData.id),
            clientId: String(responseData.clientId),
            pickupLocation: Location(
                latitude: responseData.pickupLocation.latitude,
                longitude: responseData.pickupLocation.longitude,
                address: responseData.pickupAddress
            ),
            dropoffLocation: Location(
                latitude: responseData.dropoffLocation.latitude,
                longitude: responseData.dropoffLocation.longitude,
                address: responseData.dropoffAddress
            ),
            status: RideStatus(rawValue: responseData.status) ?? .pending,
            estimatedPrice: responseData.estimatedPrice,
            finalPrice: responseData.finalPrice,
            distance: responseData.distance,
            createdAt: ISO8601DateFormatter().date(from: responseData.createdAt) ?? Date()
        )
    }
    
    func getRideHistory(for userId: String) async throws -> [Ride] {
        struct Response: Codable {
            let id: Int
            let clientId: Int
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let pickupAddress: String?
            let dropoffAddress: String?
            let status: String
            let estimatedPrice: Double
            let finalPrice: Double?
            let distance: Double?
            let createdAt: String
            let rating: Int?
            let comment: String?
        }
        
        
        guard let url = URL(string: "\(baseURL)/rides/history/\(userId)") else {
            throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "APIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let ridesData = try decoder.decode([Response].self, from: data)
        
        return ridesData.map { rideData in
            Ride(
                id: String(rideData.id),
                clientId: String(rideData.clientId),
                pickupLocation: Location(
                    latitude: rideData.pickupLocation.latitude,
                    longitude: rideData.pickupLocation.longitude,
                    address: rideData.pickupAddress
                ),
                dropoffLocation: Location(
                    latitude: rideData.dropoffLocation.latitude,
                    longitude: rideData.dropoffLocation.longitude,
                    address: rideData.dropoffAddress
                ),
                status: RideStatus(rawValue: rideData.status) ?? .pending,
                estimatedPrice: rideData.estimatedPrice,
                finalPrice: rideData.finalPrice,
                distance: rideData.distance,
                createdAt: ISO8601DateFormatter().date(from: rideData.createdAt) ?? Date()
            )
        }
    }
    
    // MARK: - Drivers
    
    /// Récupère les chauffeurs disponibles près d'une localisation
    func getAvailableDrivers(latitude: Double, longitude: Double, radius: Double = 5.0) async throws -> [User] {
        struct DriverResponse: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let driverInfo: DriverInfoResponse?
            let distance: Double?
            let location: LocationResponse?
        }
        
        struct DriverInfoResponse: Codable {
            let isOnline: Bool?
            let status: String?
            let rating: Double?
            let totalRides: Int?
            let currentLocation: LocationResponse?
        }
        
        
        let queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)")
        ]
        
        let drivers: [DriverResponse] = try await get(
            endpoint: "/location/drivers/nearby",
            queryItems: queryItems
        )
        
        return drivers.map { driverResponse in
            var driverInfo: DriverInfo? = nil
            if let driverInfoResponse = driverResponse.driverInfo {
                var currentLocation: Location? = nil
                if let locationResponse = driverInfoResponse.currentLocation {
                    currentLocation = Location(
                        latitude: locationResponse.latitude,
                        longitude: locationResponse.longitude,
                        timestamp: Date()
                    )
                } else if let locationResponse = driverResponse.location {
                    currentLocation = Location(
                        latitude: locationResponse.latitude,
                        longitude: locationResponse.longitude,
                        timestamp: Date()
                    )
                }
                
                driverInfo = DriverInfo(
                    isOnline: driverInfoResponse.isOnline,
                    status: driverInfoResponse.status,
                    currentLocation: currentLocation,
                    currentRideId: nil,
                    rating: driverInfoResponse.rating,
                    totalRides: driverInfoResponse.totalRides,
                    totalEarnings: nil,
                    licensePlate: nil,
                    vehicleType: nil,
                    documents: nil,
                    documentsStatus: nil
                )
            } else if let locationResponse = driverResponse.location {
                // Si pas de driverInfo mais une location, créer un driverInfo minimal
                driverInfo = DriverInfo(
                    isOnline: true,
                    status: "disponible",
                    currentLocation: Location(
                        latitude: locationResponse.latitude,
                        longitude: locationResponse.longitude,
                        timestamp: Date()
                    ),
                    currentRideId: nil,
                    rating: nil,
                    totalRides: nil,
                    totalEarnings: nil,
                    licensePlate: nil,
                    vehicleType: nil,
                    documents: nil,
                    documentsStatus: nil
                )
            }
            
            return User(
                id: String(driverResponse.id),
                name: driverResponse.name,
                phoneNumber: driverResponse.phoneNumber,
                email: nil,
                role: .driver,
                profileImageURL: nil,
                createdAt: Date(),
                isVerified: false,
                driverInfo: driverInfo
            )
        }
    }
    
    // MARK: - Driver Location
    
    /// Suit la position du chauffeur en temps réel pour une course (nouvel endpoint optimisé)
    func trackDriver(rideId: String) async throws -> (driverId: String, driverName: String, location: Location, status: String, estimatedArrivalMinutes: Int?) {
        struct Response: Codable {
            let success: Bool
            let rideId: Int
            let driver: DriverInfo
            let location: LocationResponse?
            let estimatedArrivalMinutes: Int?
            let rideStatus: String
            let timestamp: String
        }
        
        struct DriverInfo: Codable {
            let id: Int
            let name: String
            let phoneNumber: String?
            let status: String
            let isOnline: Bool
        }
        
        
        guard let url = URL(string: "\(baseURL)/client/track_driver/\(rideId)") else {
            throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? errorData?["message"] as? String ?? "Erreur serveur"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "APIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(Response.self, from: data)
        
        guard let locationData = responseData.location else {
            throw NSError(domain: "APIService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Position du chauffeur non disponible"])
        }
        
        let location = Location(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
            address: nil
        )
        
        return (
            driverId: String(responseData.driver.id),
            driverName: responseData.driver.name,
            location: location,
            status: responseData.driver.status,
            estimatedArrivalMinutes: responseData.estimatedArrivalMinutes
        )
    }
    
    /// Récupère la position du chauffeur assigné à une course (ancien endpoint, conservé pour compatibilité)
    func getDriverLocation(for rideId: String) async throws -> (driverId: String, driverName: String, location: Location) {
        struct Response: Codable {
            let driverId: Int
            let driverName: String
            let location: LocationResponse
            let status: String
        }
        
        
        guard let url = URL(string: "\(baseURL)/rides/\(rideId)/driver-location") else {
            throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "APIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(Response.self, from: data)
        
        let location = Location(
            latitude: responseData.location.latitude,
            longitude: responseData.location.longitude,
            address: nil
        )
        
        return (
            driverId: String(responseData.driverId),
            driverName: responseData.driverName,
            location: location
        )
    }
    
    // MARK: - Rating
    
    func rateRide(_ rideId: String, rating: Int, comment: String?, tip: Double? = nil) async throws {
        var body: [String: Any] = [
            "rating": rating
        ]
        
        if let comment = comment, !comment.isEmpty {
            body["comment"] = comment
        }
        
        if let tip = tip, tip > 0 {
            body["tip"] = tip
        }
        
        // Utiliser l'endpoint v1 client pour l'évaluation
        guard let url = URL(string: "\(baseURL)/v1/client/rate/\(rideId)") else {
            throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Erreur serveur"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "APIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
    
    // MARK: - Ride Details
    
    /// Récupère les détails d'une course
    func getRideDetails(rideId: String) async throws -> Ride {
        struct Response: Codable {
            let id: Int
            let clientId: Int
            let driverId: Int?
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let pickupAddress: String?
            let dropoffAddress: String?
            let status: String
            let estimatedPrice: Double
            let finalPrice: Double?
            let distance: Double?
            let createdAt: String
            let startedAt: String?
            let completedAt: String?
            let rating: Int?
            let review: String?
        }
        
        
        guard let url = URL(string: "\(baseURL)/rides/\(rideId)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseData = try decoder.decode(Response.self, from: data)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Ride(
            id: String(responseData.id),
            clientId: String(responseData.clientId),
            driverId: responseData.driverId != nil ? String(responseData.driverId!) : nil,
            pickupLocation: Location(
                latitude: responseData.pickupLocation.latitude,
                longitude: responseData.pickupLocation.longitude,
                address: responseData.pickupAddress
            ),
            dropoffLocation: Location(
                latitude: responseData.dropoffLocation.latitude,
                longitude: responseData.dropoffLocation.longitude,
                address: responseData.dropoffAddress
            ),
            status: RideStatus(rawValue: responseData.status) ?? .pending,
            estimatedPrice: responseData.estimatedPrice,
            finalPrice: responseData.finalPrice,
            distance: responseData.distance,
            createdAt: formatter.date(from: responseData.createdAt) ?? Date(),
            startedAt: responseData.startedAt != nil ? formatter.date(from: responseData.startedAt!) : nil,
            completedAt: responseData.completedAt != nil ? formatter.date(from: responseData.completedAt!) : nil,
            rating: responseData.rating,
            review: responseData.review
        )
    }
    
    // MARK: - Estimate Price with Vehicle Category
    
    /// Calcule le prix estimé avec catégorie de véhicule
    func estimatePrice(pickup: Location, dropoff: Location, vehicleCategory: String, distance: Double? = nil) async throws -> PriceEstimate {
        let body: [String: Any] = [
            "pickupLocation": [
                "latitude": pickup.latitude,
                "longitude": pickup.longitude,
                "address": pickup.address ?? ""
            ],
            "dropoffLocation": [
                "latitude": dropoff.latitude,
                "longitude": dropoff.longitude,
                "address": dropoff.address ?? ""
            ],
            "vehicleCategory": vehicleCategory,
            "distance": distance as Any
        ]
        
        guard let url = URL(string: "\(baseURL)/v1/client/estimate") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(type: .unknown, message: "Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur lors de l'estimation du prix"
                
                throw APIError(
                    type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                          httpResponse.statusCode == 404 ? .notFound :
                          httpResponse.statusCode >= 500 ? .server : .validation,
                    message: message,
                    statusCode: httpResponse.statusCode
                )
            }
            
            struct Response: Codable {
                let success: Bool
                let price: Double
                let basePrice: Double
                let distance: Double
                let explanation: String
                let multipliers: Multipliers
                let breakdown: PriceBreakdown
            }
            
            struct Multipliers: Codable {
                let time: Double
                let day: Double
                let surge: Double
            }
            
            struct PriceBreakdown: Codable {
                let base: Double
                let distance: Double
                let timeAdjustment: Double
                let dayAdjustment: Double
                let surgeAdjustment: Double
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let responseData = try decoder.decode(Response.self, from: data)
            
            return PriceEstimate(
                price: responseData.price,
                basePrice: responseData.basePrice,
                distance: responseData.distance,
                explanation: responseData.explanation,
                multipliers: PriceMultipliers(
                    time: responseData.multipliers.time,
                    day: responseData.multipliers.day,
                    surge: responseData.multipliers.surge
                ),
                breakdown: PriceBreakdownData(
                    base: responseData.breakdown.base,
                    distance: responseData.breakdown.distance,
                    timeAdjustment: responseData.breakdown.timeAdjustment,
                    dayAdjustment: responseData.breakdown.dayAdjustment,
                    surgeAdjustment: responseData.breakdown.surgeAdjustment
                )
            )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(error)
        }
    }
    
    // MARK: - Driver Info
    
    /// Récupère les informations d'un conducteur
    func getDriverInfo(driverId: String) async throws -> User {
        struct Response: Codable {
            let id: Int
            let name: String
            let phoneNumber: String
            let email: String?
            let profileImageURL: String?
            let driverInfo: DriverInfoResponse?
        }
        
        struct DriverInfoResponse: Codable {
            let isOnline: Bool?
            let status: String?
            let rating: Double?
            let totalRides: Int?
            let currentLocation: LocationResponse?
        }
        
        
        guard let url = URL(string: "\(baseURL)/users/\(driverId)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseData = try decoder.decode(Response.self, from: data)
        
        var driverInfo: DriverInfo? = nil
        if let driverInfoResponse = responseData.driverInfo {
            var currentLocation: Location? = nil
            if let locationResponse = driverInfoResponse.currentLocation {
                currentLocation = Location(
                    latitude: locationResponse.latitude,
                    longitude: locationResponse.longitude,
                    timestamp: Date()
                )
            }
            
            driverInfo = DriverInfo(
                isOnline: driverInfoResponse.isOnline,
                status: driverInfoResponse.status,
                currentLocation: currentLocation,
                currentRideId: nil,
                rating: driverInfoResponse.rating,
                totalRides: driverInfoResponse.totalRides,
                totalEarnings: nil,
                licensePlate: nil,
                vehicleType: nil,
                documents: nil,
                documentsStatus: nil
            )
        }
        
        return User(
            id: String(responseData.id),
            name: responseData.name,
            phoneNumber: responseData.phoneNumber,
            email: responseData.email,
            role: .driver,
            profileImageURL: responseData.profileImageURL,
            createdAt: Date(),
            isVerified: false,
            driverInfo: driverInfo
        )
    }
    
    // MARK: - Payment
    
    /// Confirme un paiement
    func confirmPayment(rideId: String, paymentIntentId: String) async throws {
        let body: [String: Any] = [
            "rideId": rideId,
            "paymentIntentId": paymentIntentId
        ]
        
        try await post(endpoint: "/paiements/confirm", body: body)
    }
    
    // MARK: - Scheduled Rides
    
    /// Récupère les courses programmées
    func getScheduledRides() async throws -> [ScheduledRide] {
        struct Response: Codable {
            let id: String
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let scheduledDate: String
            let vehicleType: String
            let paymentMethod: String
            let status: String
            let createdAt: String
        }
        
        struct ScheduledRidesResponse: Codable {
            let scheduledRides: [Response]
        }
        
        let response: ScheduledRidesResponse = try await get(endpoint: "/scheduled-rides", queryItems: nil)
        let scheduledRides = response.scheduledRides
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return scheduledRides.map { rideData in
            ScheduledRide(
                id: rideData.id,
                pickupLocation: Location(
                    latitude: rideData.pickupLocation.latitude,
                    longitude: rideData.pickupLocation.longitude,
                    address: rideData.pickupLocation.address
                ),
                dropoffLocation: Location(
                    latitude: rideData.dropoffLocation.latitude,
                    longitude: rideData.dropoffLocation.longitude,
                    address: rideData.dropoffLocation.address
                ),
                scheduledDate: formatter.date(from: rideData.scheduledDate) ?? Date(),
                status: ScheduledRideStatus(rawValue: rideData.status) ?? .pending,
                vehicleType: VehicleType(rawValue: rideData.vehicleType) ?? .economy,
                paymentMethod: PaymentMethod(rawValue: rideData.paymentMethod) ?? .cash,
                createdAt: formatter.date(from: rideData.createdAt) ?? Date()
            )
        }
    }
    
    /// Crée une course programmée
    func createScheduledRide(
        pickupLocation: Location,
        dropoffLocation: Location,
        scheduledDate: Date,
        vehicleType: VehicleType,
        paymentMethod: PaymentMethod
    ) async throws -> ScheduledRide {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let body: [String: Any] = [
            "pickupLocation": [
                "latitude": pickupLocation.latitude,
                "longitude": pickupLocation.longitude,
                "address": pickupLocation.address ?? ""
            ],
            "dropoffLocation": [
                "latitude": dropoffLocation.latitude,
                "longitude": dropoffLocation.longitude,
                "address": dropoffLocation.address ?? ""
            ],
            "scheduledDate": formatter.string(from: scheduledDate),
            "vehicleType": vehicleType.rawValue,
            "paymentMethod": paymentMethod.rawValue
        ]
        
        struct Response: Codable {
            let id: String
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let scheduledDate: String
            let vehicleType: String
            let paymentMethod: String
            let status: String
            let createdAt: String
        }
        
        guard let url = URL(string: "\(baseURL)/scheduled-rides") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
        
        struct CreateScheduledRideResponse: Codable {
            let scheduledRide: ScheduledRideData
        }
        
        struct ScheduledRideData: Codable {
            let id: String
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let scheduledDate: String
            let vehicleType: String
            let paymentMethod: String
            let status: String
            let createdAt: String
        }
        
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseWrapper = try decoder.decode(CreateScheduledRideResponse.self, from: data)
        let responseData = responseWrapper.scheduledRide
        
        return ScheduledRide(
            id: responseData.id,
            pickupLocation: Location(
                latitude: responseData.pickupLocation.latitude,
                longitude: responseData.pickupLocation.longitude,
                address: responseData.pickupLocation.address
            ),
            dropoffLocation: Location(
                latitude: responseData.dropoffLocation.latitude,
                longitude: responseData.dropoffLocation.longitude,
                address: responseData.dropoffLocation.address
            ),
            scheduledDate: formatter.date(from: responseData.scheduledDate) ?? Date(),
            status: ScheduledRideStatus(rawValue: responseData.status) ?? .pending,
            vehicleType: VehicleType(rawValue: responseData.vehicleType) ?? .economy,
            paymentMethod: PaymentMethod(rawValue: responseData.paymentMethod) ?? .cash,
            createdAt: formatter.date(from: responseData.createdAt) ?? Date()
        )
    }
    
    /// Annule une course programmée
    func cancelScheduledRide(scheduledRideId: String) async throws {
        guard let url = URL(string: "\(baseURL)/scheduled-rides/\(scheduledRideId)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: Data())
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
    }
    
    /// Met à jour une course programmée
    func updateScheduledRide(
        _ rideId: String,
        pickupLocation: Location? = nil,
        dropoffLocation: Location? = nil,
        scheduledDate: Date? = nil
    ) async throws -> ScheduledRide {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var body: [String: Any] = [:]
        
        if let pickupLocation = pickupLocation {
            body["pickupLocation"] = [
                "latitude": pickupLocation.latitude,
                "longitude": pickupLocation.longitude,
                "address": pickupLocation.address ?? ""
            ]
        }
        
        if let dropoffLocation = dropoffLocation {
            body["dropoffLocation"] = [
                "latitude": dropoffLocation.latitude,
                "longitude": dropoffLocation.longitude,
                "address": dropoffLocation.address ?? ""
            ]
        }
        
        if let scheduledDate = scheduledDate {
            body["scheduledDate"] = formatter.string(from: scheduledDate)
        }
        
        
        guard let url = URL(string: "\(baseURL)/scheduled-rides/\(rideId)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
        
        struct UpdateScheduledRideResponse: Codable {
            let scheduledRide: ScheduledRideData
        }
        
        struct ScheduledRideData: Codable {
            let id: String
            let pickupLocation: LocationResponse
            let dropoffLocation: LocationResponse
            let scheduledDate: String
            let vehicleType: String
            let paymentMethod: String
            let status: String
            let createdAt: String
        }
        
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseWrapper = try decoder.decode(UpdateScheduledRideResponse.self, from: data)
        let responseData = responseWrapper.scheduledRide
        
        return ScheduledRide(
            id: responseData.id,
            pickupLocation: Location(
                latitude: responseData.pickupLocation.latitude,
                longitude: responseData.pickupLocation.longitude,
                address: responseData.pickupLocation.address
            ),
            dropoffLocation: Location(
                latitude: responseData.dropoffLocation.latitude,
                longitude: responseData.dropoffLocation.longitude,
                address: responseData.dropoffLocation.address
            ),
            scheduledDate: formatter.date(from: responseData.scheduledDate) ?? Date(),
            status: ScheduledRideStatus(rawValue: responseData.status) ?? .pending,
            vehicleType: VehicleType(rawValue: responseData.vehicleType) ?? .economy,
            paymentMethod: PaymentMethod(rawValue: responseData.paymentMethod) ?? .cash,
            createdAt: formatter.date(from: responseData.createdAt) ?? Date()
        )
    }
    
    // MARK: - Chat
    
    /// Récupère les messages de chat pour une course
    func getChatMessages(rideId: String) async throws -> [ChatMessage] {
        struct Response: Codable {
            let id: String
            let message: String
            let senderId: String
            let senderName: String
            let timestamp: String
            let isFromDriver: Bool
        }
        
        struct MessagesResponse: Codable {
            let messages: [Response]
        }
        
        let response: MessagesResponse = try await get(endpoint: "/chat/\(rideId)/messages", queryItems: nil)
        let messages = response.messages
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return messages.map { messageData in
            ChatMessage(
                id: messageData.id,
                message: messageData.message,
                senderId: messageData.senderId,
                senderName: messageData.senderName,
                timestamp: formatter.date(from: messageData.timestamp) ?? Date(),
                isFromDriver: messageData.isFromDriver
            )
        }
    }
    
    /// Envoie un message de chat
    func sendChatMessage(rideId: String, message: String) async throws {
        let body: [String: Any] = [
            "message": message
        ]
        
        try await post(endpoint: "/chat/\(rideId)/messages", body: body)
    }
    
    /// Marque un message comme lu
    func markMessageAsRead(messageId: String) async throws {
        guard let url = URL(string: "\(baseURL)/chat/messages/\(messageId)/read") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: Data())
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
    }
    
    // MARK: - SOS
    
    /// Envoie une alerte SOS
    func sendSOSAlert(location: Location, message: String? = nil, userId: String? = nil) async throws {
        var body: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude
        ]
        
        if let message = message {
            body["message"] = message
        }
        
        // Le rideId peut être ajouté si disponible
        // body["rideId"] = rideId
        
        try await post(endpoint: "/sos", body: body)
    }
    
    /// Désactive une alerte SOS
    func deactivateSOSAlert(userId: String? = nil) async throws {
        let userIdToUse = userId ?? config.getUserId() ?? ""
        try await post(endpoint: "/sos/\(userIdToUse)/deactivate", body: [:])
    }
    
    // MARK: - Share
    
    /// Génère un lien de partage pour une course
    func generateShareLink(rideId: String) async throws -> String {
        struct Response: Codable {
            let shareLink: String
        }
        
        let response: Response = try await get(endpoint: "/rides/\(rideId)/share", queryItems: nil)
        
        return response.shareLink
    }
    
    /// Partage une course avec des contacts
    func shareRide(rideId: String, contacts: [String], link: String) async throws {
        let body: [String: Any] = [
            "rideId": rideId,
            "contacts": contacts,
            "link": link
        ]
        
        try await post(endpoint: "/share/ride", body: body)
    }
    
    /// Partage une position en temps réel
    func shareLocation(rideId: String, location: Location) async throws {
        let body: [String: Any] = [
            "rideId": rideId,
            "location": [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address ?? ""
            ]
        ]
        
        try await post(endpoint: "/share/location", body: body)
    }
    
    /// Récupère les courses partagées
    func getSharedRides() async throws -> [SharedRide] {
        struct Response: Codable {
            let id: String
            let rideId: String
            let shareLink: String
            let sharedWith: [String]
            let createdAt: String
            let expiresAt: String?
        }
        
        struct SharedRidesResponse: Codable {
            let sharedRides: [Response]
        }
        
        let response: SharedRidesResponse = try await get(endpoint: "/share/rides", queryItems: nil)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return response.sharedRides.map { rideData in
            SharedRide(
                id: rideData.id,
                rideId: rideData.rideId,
                sharedWith: rideData.sharedWith,
                shareLink: rideData.shareLink,
                createdAt: formatter.date(from: rideData.createdAt) ?? Date(),
                expiresAt: rideData.expiresAt != nil ? formatter.date(from: rideData.expiresAt!) : nil
            )
        }
    }
    
    // MARK: - Support
    
    /// Envoie un message de support
    func sendSupportMessage(message: String) async throws {
        let body: [String: Any] = [
            "message": message
        ]
        
        try await post(endpoint: "/support/message", body: body)
    }
    
    /// Récupère les messages de support
    func getSupportMessages() async throws -> [SupportMessage] {
        struct Response: Codable {
            let id: String
            let message: String
            let isFromUser: Bool
            let timestamp: String
        }
        
        struct MessagesResponse: Codable {
            let messages: [Response]
        }
        
        let response: MessagesResponse = try await get(endpoint: "/support/messages", queryItems: nil)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return response.messages.map { messageData in
            SupportMessage(
                id: messageData.id,
                message: messageData.message,
                isFromUser: messageData.isFromUser,
                timestamp: formatter.date(from: messageData.timestamp) ?? Date()
            )
        }
    }
    
    /// Crée un ticket de support
    func createSupportTicket(subject: String, message: String, category: String) async throws -> SupportTicket {
        let body: [String: Any] = [
            "subject": subject,
            "message": message,
            "category": category
        ]
        
        struct Response: Codable {
            let ticket: SupportTicketResponse
        }
        
        struct SupportTicketResponse: Codable {
            let id: String
            let subject: String
            let message: String
            let category: String
            let status: String
            let createdAt: String
            let updatedAt: String
        }
        
        guard let url = URL(string: "\(baseURL)/support/ticket") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let responseData = try decoder.decode(Response.self, from: data)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return SupportTicket(
            id: responseData.ticket.id,
            subject: responseData.ticket.subject,
            message: responseData.ticket.message,
            category: responseData.ticket.category,
            status: responseData.ticket.status,
            priority: nil,
            createdAt: formatter.date(from: responseData.ticket.createdAt) ?? Date(),
            updatedAt: formatter.date(from: responseData.ticket.updatedAt) ?? Date(),
            resolvedAt: nil
        )
    }
    
    /// Récupère les tickets de support
    func getSupportTickets() async throws -> [SupportTicket] {
        struct Response: Codable {
            let id: String
            let subject: String
            let message: String
            let category: String
            let status: String
            let createdAt: String
            let updatedAt: String
        }
        
        struct TicketsResponse: Codable {
            let tickets: [Response]
        }
        
        let response: TicketsResponse = try await get(endpoint: "/support/tickets", queryItems: nil)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return response.tickets.map { ticketData in
            SupportTicket(
                id: ticketData.id,
                subject: ticketData.subject,
                message: ticketData.message,
                category: ticketData.category,
                status: ticketData.status,
                priority: nil,
                createdAt: formatter.date(from: ticketData.createdAt) ?? Date(),
                updatedAt: formatter.date(from: ticketData.updatedAt) ?? Date(),
                resolvedAt: nil
            )
        }
    }
    
    /// Signale un problème
    func reportProblem(description: String, category: String) async throws {
        let body: [String: Any] = [
            "description": description,
            "category": category
        ]
        
        try await post(endpoint: "/support/report", body: body)
    }
    
    /// Récupère la FAQ
    func getFAQ() async throws -> [FAQItem] {
        struct FAQItemResponse: Codable {
            let id: String
            let question: String
            let answer: String
        }
        
        struct FAQResponse: Codable {
            let faq: [FAQItemResponse]
        }
        
        let response: FAQResponse = try await get(endpoint: "/support/faq", queryItems: nil)
        
        return response.faq.map { item in
            FAQItem(
                id: item.id,
                question: item.question,
                answer: item.answer
            )
        }
    }
    
    // MARK: - Favorites
    
    /// Récupère les adresses favorites
    func getFavoriteAddresses() async throws -> [SavedAddress] {
        struct Response: Codable {
            let id: String
            let name: String
            let address: String
            let location: LocationResponse
            let icon: String?
            let isFavorite: Bool
            let createdAt: String
        }
        
        
        struct FavoritesResponse: Codable {
            let favorites: [Response]
        }
        
        let response: FavoritesResponse = try await get(endpoint: "/favorites", queryItems: nil)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return response.favorites.map { favoriteData in
            SavedAddress(
                id: favoriteData.id,
                name: favoriteData.name,
                address: favoriteData.address,
                location: Location(
                    latitude: favoriteData.location.latitude,
                    longitude: favoriteData.location.longitude,
                    address: favoriteData.address
                ),
                icon: favoriteData.icon,
                isFavorite: favoriteData.isFavorite,
                createdAt: formatter.date(from: favoriteData.createdAt) ?? Date()
            )
        }
    }
    
    /// Ajoute une adresse favorite
    func addFavoriteAddress(_ address: SavedAddress) async throws {
        let body: [String: Any] = [
            "name": address.name,
            "address": address.address,
            "location": [
                "latitude": address.location.latitude,
                "longitude": address.location.longitude,
                "address": address.location.address ?? ""
            ],
            "icon": address.icon ?? "mappin.circle.fill"
        ]
        
        try await post(endpoint: "/favorites", body: body)
    }
    
    /// Supprime une adresse favorite
    func removeFavoriteAddress(_ addressId: String) async throws {
        guard let url = URL(string: "\(baseURL)/favorites/\(addressId)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: Data())
            let message = errorMessage?["error"] ?? errorMessage?["message"] ?? "Erreur serveur"
            
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: message,
                statusCode: httpResponse.statusCode
            )
        }
    }
    
    /// Met à jour une adresse favorite
    func updateFavoriteAddress(_ address: SavedAddress) async throws {
        let body: [String: Any] = [
            "name": address.name,
            "address": address.address,
            "location": [
                "latitude": address.location.latitude,
                "longitude": address.location.longitude,
                "address": address.location.address ?? ""
            ],
            "icon": address.icon ?? "mappin.circle.fill"
        ]
        
        guard let url = URL(string: "\(baseURL)/favorites/\(address.id)") else {
            throw APIError(type: .validation, message: "URL invalide")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = config.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.httpTimeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(type: .unknown, message: "Réponse invalide du serveur")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError(
                type: httpResponse.statusCode == 401 || httpResponse.statusCode == 403 ? .authentication :
                      httpResponse.statusCode == 404 ? .notFound :
                      httpResponse.statusCode >= 500 ? .server : .validation,
                message: "Erreur lors de la mise à jour",
                statusCode: httpResponse.statusCode
            )
        }
    }
}
