//
//  AuthViewModel.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private let googleAuth = GoogleAuthService.shared
    
    /// Inscription avec mot de passe
    func register(phoneNumber: String, name: String, password: String, role: UserRole = .client) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let (token, user) = try await apiService.register(
                phoneNumber: phoneNumber,
                name: name,
                password: password,
                role: role
            )
            
            // Sauvegarder le token
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(user.id, forKey: "user_id")
            UserDefaults.standard.set(role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Inscription réussie - User ID: \(user.id), Token sauvegardé: \(token.prefix(20))...")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'inscription: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur register: \(error)")
            }
        }
    }
    
    /// Connexion avec mot de passe
    func login(phoneNumber: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let (token, user) = try await apiService.login(
                phoneNumber: phoneNumber,
                password: password
            )
            
            // Sauvegarder le token
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(user.id, forKey: "user_id")
            UserDefaults.standard.set(user.role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Connexion réussie - User ID: \(user.id), Token sauvegardé: \(token.prefix(20))...")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la connexion: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur login: \(error)")
            }
        }
    }
    
    /// Connexion avec numéro de téléphone utilisant l'API /auth/signin (ancienne méthode - gardée pour compatibilité)
    func signIn(phoneNumber: String, role: UserRole, userName: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Utiliser l'API /auth/signin qui retourne un token JWT
            let (token, user) = try await apiService.signIn(
                phoneNumber: phoneNumber,
                role: role,
                name: userName
            )
            
            // Sauvegarder le token dans ConfigurationService (utilisé par APIService)
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            // Sauvegarder aussi dans UserDefaults avec la même clé que AuthManager
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Authentification réussie - Token sauvegardé: \(token.prefix(20))...")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la connexion: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur signIn: \(error)")
            }
        }
    }
    
    /// Met à jour le profil utilisateur
    func updateProfile(name: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let updatedUser = try await apiService.updateProfile(name: name)
            await MainActor.run {
                currentUser = updatedUser
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    /// Met à jour la photo de profil
    func updateProfileImage(_ image: UIImage) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Convertir l'image en base64
            guard let base64String = ImageService.shared.imageToBase64(image) else {
                throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image"])
            }
            
            // Créer une URL de données base64
            let profileImageURL = "data:image/jpeg;base64,\(base64String)"
            
            // Sauvegarder l'image localement
            ImageService.shared.saveProfileImage(image)
            
            // Obtenir le nom actuel de l'utilisateur
            let currentName = currentUser?.name ?? ""
            
            // Mettre à jour le profil avec la nouvelle image
            let updatedUser = try await apiService.updateProfile(name: currentName, profileImageURL: profileImageURL)
            await MainActor.run {
                currentUser = updatedUser
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour de la photo: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    /// Supprime la photo de profil
    func deleteProfileImage() async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Supprimer l'image locale
            ImageService.shared.deleteProfileImage()
            
            // Obtenir le nom actuel de l'utilisateur
            let currentName = currentUser?.name ?? ""
            
            // Mettre à jour le profil avec une URL vide
            let updatedUser = try await apiService.updateProfile(name: currentName, profileImageURL: nil)
            await MainActor.run {
                currentUser = updatedUser
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la suppression de la photo: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func signOut() async {
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    func checkAuthStatus() {
        // Vérifier si un token existe et charger le profil utilisateur
        let config = ConfigurationService.shared
        if let token = config.getAuthToken(), !token.isEmpty {
            // Charger le profil utilisateur depuis l'API
            Task {
                await loadUserProfile()
            }
        }
    }
    
    /// Charge le profil utilisateur depuis l'API
    func loadUserProfile() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let user = try await apiService.getUserProfile()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ AuthViewModel: Profil utilisateur chargé - User ID: \(user.id)")
        } catch {
            await MainActor.run {
                isLoading = false
                // Ne pas déconnecter l'utilisateur en cas d'erreur, juste ne pas charger le profil
                print("⚠️ AuthViewModel: Impossible de charger le profil - \(error.localizedDescription)")
            }
        }
    }
    
    /// Envoie un code OTP au numéro de téléphone
    func sendOTP(phoneNumber: String, channel: String = "whatsapp") async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await apiService.sendOTP(phoneNumber: phoneNumber, channel: channel)
            
            await MainActor.run {
                isLoading = false
                // Le code est envoyé, pas besoin de mettre à jour l'état utilisateur ici
                if let code = result.code {
                    print("✅ Code OTP envoyé via \(result.channel) - Code (dev): \(code)")
                } else {
                    print("✅ Code OTP envoyé via \(result.channel)")
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du code: \(error.localizedDescription)"
                isLoading = false
                print("❌ Erreur sendOTP: \(error)")
            }
        }
    }
    
    /// Vérifie le code OTP et connecte l'utilisateur
    func verifyOTP(phoneNumber: String, code: String, role: UserRole, userName: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let (token, user) = try await apiService.verifyOTP(
                phoneNumber: phoneNumber,
                code: code,
                role: role,
                name: userName
            )
            
            // Sauvegarder le token
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Vérification OTP réussie - Token sauvegardé: \(token.prefix(20))...")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la vérification: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur verifyOTP: \(error)")
            }
        }
    }
    
    /// Connexion avec Google Sign-In
    func signInWithGoogle(presentingViewController: UIViewController) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Authentifier avec Google
            let googleUser = try await googleAuth.signIn(presentingViewController: presentingViewController)
            
            // 2. Envoyer le token au backend
            let (token, user) = try await apiService.signInWithGoogle(
                idToken: googleUser.idToken,
                email: googleUser.email,
                name: googleUser.name,
                photoURL: googleUser.photoURL
            )
            
            // 3. Sauvegarder le token
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(user.role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Authentification Google réussie - Token sauvegardé: \(token.prefix(20))...")
        } catch let error as GoogleAuthError {
            await MainActor.run {
                if case .cancelled = error {
                    // L'utilisateur a annulé, ne pas afficher d'erreur
                    isLoading = false
                } else {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    isAuthenticated = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la connexion Google: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur signInWithGoogle: \(error)")
            }
        }
    }
    
    /// Demande de réinitialisation de mot de passe
    func forgotPassword(phoneNumber: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.forgotPassword(phoneNumber: phoneNumber)
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Code de réinitialisation envoyé")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du code: \(error.localizedDescription)"
                isLoading = false
                print("❌ Erreur forgotPassword: \(error)")
            }
        }
    }
    
    /// Réinitialise le mot de passe avec un code OTP
    func resetPassword(phoneNumber: String, code: String, newPassword: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.resetPassword(
                phoneNumber: phoneNumber,
                code: code,
                newPassword: newPassword
            )
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Mot de passe réinitialisé avec succès")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la réinitialisation: \(error.localizedDescription)"
                isLoading = false
                print("❌ Erreur resetPassword: \(error)")
            }
        }
    }
    
    /// Change le mot de passe (nécessite authentification)
    func changePassword(currentPassword: String, newPassword: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Mot de passe modifié avec succès")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du changement de mot de passe: \(error.localizedDescription)"
                isLoading = false
                print("❌ Erreur changePassword: \(error)")
            }
        }
    }
    
    /// Définit un mot de passe pour les utilisateurs existants sans mot de passe
    func setPassword(phoneNumber: String, code: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let (token, user) = try await apiService.setPassword(
                phoneNumber: phoneNumber,
                code: code,
                password: password
            )
            
            // Sauvegarder le token
            config.setAuthToken(token)
            config.setUserId(user.id)
            config.setUserRole(user.role)
            
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults.standard.set(user.id, forKey: "user_id")
            UserDefaults.standard.set(user.role.rawValue, forKey: "user_role")
            UserDefaults.standard.synchronize()
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            print("✅ Mot de passe défini avec succès - User ID: \(user.id), Token sauvegardé: \(token.prefix(20))...")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la définition du mot de passe: \(error.localizedDescription)"
                isLoading = false
                isAuthenticated = false
                print("❌ Erreur setPassword: \(error)")
            }
        }
    }
}
