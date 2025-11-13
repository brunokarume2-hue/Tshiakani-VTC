//
//  BackendConnectionTestService.swift
//  Tshiakani VTC
//
//  Service pour tester la connexion au backend
//

import Foundation
import Combine

/// Service pour tester la connexion au backend
class BackendConnectionTestService: ObservableObject {
    static let shared = BackendConnectionTestService()
    
    @Published var isBackendConnected = false
    @Published var backendURL: String = ""
    @Published var lastError: String?
    @Published var testResults: [TestResult] = []
    
    private let config = ConfigurationService.shared
    private let apiService = APIService.shared
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    private init() {
        backendURL = config.apiBaseURL
    }
    
    // MARK: - Tests de Connexion
    
    /// Teste la connexion au backend
    func testConnection() async {
        await MainActor.run {
            testResults.removeAll()
            isBackendConnected = false
            lastError = nil
        }
        
        // Test 1: Health Check
        await testHealthCheck()
        
        // Test 2: Authentification
        await testAuthentication()
        
        // Test 3: Vérifier les endpoints
        await testEndpoints()
    }
    
    /// Teste le Health Check
    private func testHealthCheck() async {
        let healthURL = config.apiBaseURL.replacingOccurrences(of: "/api", with: "") + "/health"
        
        guard let url = URL(string: healthURL) else {
            await MainActor.run {
                testResults.append(TestResult(
                    testName: "Health Check",
                    success: false,
                    message: "URL invalide: \(healthURL)",
                    timestamp: Date()
                ))
            }
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    await MainActor.run {
                        testResults.append(TestResult(
                            testName: "Health Check",
                            success: true,
                            message: "Backend accessible",
                            timestamp: Date()
                        ))
                        isBackendConnected = true
                    }
                } else {
                    await MainActor.run {
                        testResults.append(TestResult(
                            testName: "Health Check",
                            success: false,
                            message: "Status code: \(httpResponse.statusCode)",
                            timestamp: Date()
                        ))
                    }
                }
            }
        } catch {
            await MainActor.run {
                let errorMessage = error.localizedDescription
                testResults.append(TestResult(
                    testName: "Health Check",
                    success: false,
                    message: errorMessage,
                    timestamp: Date()
                ))
                lastError = errorMessage
            }
        }
    }
    
    /// Teste l'authentification
    private func testAuthentication() async {
        do {
            let testPhoneNumber = "+243900000000"
            let body: [String: Any] = [
                "phoneNumber": testPhoneNumber,
                "role": "client"
            ]
            
            try await apiService.post(endpoint: "/auth/signin", body: body)
            
            await MainActor.run {
                testResults.append(TestResult(
                    testName: "Authentification",
                    success: true,
                    message: "Authentification réussie",
                    timestamp: Date()
                ))
            }
        } catch {
            await MainActor.run {
                let errorMessage = error.localizedDescription
                testResults.append(TestResult(
                    testName: "Authentification",
                    success: false,
                    message: errorMessage,
                    timestamp: Date()
                ))
            }
        }
    }
    
    /// Teste les endpoints principaux
    private func testEndpoints() async {
        // Test de l'endpoint d'estimation de prix
        await testEstimatePrice()
    }
    
    /// Teste l'endpoint d'estimation de prix
    private func testEstimatePrice() async {
        guard config.getAuthToken() != nil else {
            await MainActor.run {
                testResults.append(TestResult(
                    testName: "Estimation de prix",
                    success: false,
                    message: "Token JWT non disponible",
                    timestamp: Date()
                ))
            }
            return
        }
        
        do {
            let body: [String: Any] = [
                "pickupLocation": [
                    "latitude": -4.3276,
                    "longitude": 15.3136
                ],
                "dropoffLocation": [
                    "latitude": -4.3296,
                    "longitude": 15.3156
                ]
            ]
            
            try await apiService.post(endpoint: "/rides/estimate-price", body: body)
            
            await MainActor.run {
                testResults.append(TestResult(
                    testName: "Estimation de prix",
                    success: true,
                    message: "Estimation réussie",
                    timestamp: Date()
                ))
            }
        } catch {
            await MainActor.run {
                let errorMessage = error.localizedDescription
                testResults.append(TestResult(
                    testName: "Estimation de prix",
                    success: false,
                    message: errorMessage,
                    timestamp: Date()
                ))
            }
        }
    }
    
    // MARK: - Informations de Connexion
    
    /// Récupère les informations de connexion
    func getConnectionInfo() -> ConnectionInfo {
        return ConnectionInfo(
            apiBaseURL: config.apiBaseURL,
            socketBaseURL: config.socketBaseURL,
            hasAuthToken: config.getAuthToken() != nil,
            authToken: config.getAuthToken()?.prefix(20).appending("...") ?? "Aucun token"
        )
    }
    
    struct ConnectionInfo {
        let apiBaseURL: String
        let socketBaseURL: String
        let hasAuthToken: Bool
        let authToken: String
    }
}

