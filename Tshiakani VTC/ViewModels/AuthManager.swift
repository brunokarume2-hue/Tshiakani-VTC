//
//  AuthManager.swift
//  Tshiakani VTC
//
//  Gestionnaire d'authentification global avec gestion de l'onboarding
//

import Foundation
import SwiftUI
import Combine

/// Gestionnaire d'authentification global qui gère l'état de l'application
class AuthManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Statut d'authentification (déterminé par la présence d'un token utilisateur)
    @Published var isAuthenticated: Bool = false
    
    /// Rôle de l'utilisateur actuel
    @Published var userRole: UserRole? = nil
    
    /// Indique si l'utilisateur a déjà vu l'onboarding
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    // MARK: - Private Properties
    
    private let tokenKey = "auth_token"
    private let userRoleKey = "user_role"
    private let apiService = APIService.shared
    
    // MARK: - Initialization
    
    init() {
        // Vérifier l'état d'authentification au démarrage
        checkAuthStatus()
    }
    
    // MARK: - Authentication Management
    
    /// Vérifie le statut d'authentification en vérifiant la présence d'un token
    func checkAuthStatus() {
        // Vérifier si un token existe (peut être dans ConfigurationService ou UserDefaults)
        let config = ConfigurationService.shared
        let token = config.getAuthToken() ?? UserDefaults.standard.string(forKey: tokenKey)
        
        if let token = token, !token.isEmpty {
            isAuthenticated = true
            
            // Récupérer le rôle sauvegardé
            if let role = config.getUserRole() {
                userRole = role
            } else if let roleString = UserDefaults.standard.string(forKey: userRoleKey),
               let role = UserRole(rawValue: roleString) {
                userRole = role
            }
        } else {
            isAuthenticated = false
            userRole = nil
        }
    }
    
    /// Sauvegarde le token et le rôle après authentification réussie
    func saveAuthToken(_ token: String, role: UserRole) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(role.rawValue, forKey: userRoleKey)
        
        // Forcer la synchronisation immédiate
        UserDefaults.standard.synchronize()
        
        // Mettre à jour l'état sur le thread principal de manière synchrone si on est déjà sur le main thread
        if Thread.isMainThread {
            self.isAuthenticated = true
            self.userRole = role
            print("✅ AuthManager: État mis à jour - isAuthenticated: \(self.isAuthenticated), role: \(self.userRole?.rawValue ?? "nil")")
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isAuthenticated = true
                self?.userRole = role
                print("✅ AuthManager: État mis à jour (async) - isAuthenticated: \(self?.isAuthenticated ?? false), role: \(self?.userRole?.rawValue ?? "nil")")
            }
        }
    }
    
    /// Marque l'onboarding comme vu
    func completeOnboarding() {
        hasSeenOnboarding = true
    }
    
    /// Déconnecte l'utilisateur
    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userRoleKey)
        
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticated = false
            self?.userRole = nil
        }
    }
    
    /// Récupère le token actuel
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
}

