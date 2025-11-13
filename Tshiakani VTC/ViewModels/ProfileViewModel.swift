//
//  ProfileViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer le profil utilisateur
//

import Foundation
import SwiftUI
import Combine
import UIKit

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEditing: Bool = false
    
    // Profile fields
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String?
    
    // Preferences
    @Published var language: String = "fr"
    @Published var city: String = "Kinshasa"
    @Published var notificationsEnabled: Bool = true
    @Published var locationSharingEnabled: Bool = true
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let authViewModel = AuthViewModel()
    private let config = ConfigurationService.shared
    private let imageService = ImageService.shared
    private let userPreferences = UserPreferencesService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadUserProfile()
        loadPreferences()
    }
    
    // MARK: - Load Profile
    
    func loadUserProfile() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let user = try await apiService.getUserProfile()
                
                await MainActor.run {
                    currentUser = user
                    name = user.name
                    phoneNumber = user.phoneNumber
                    email = user.email ?? ""
                    profileImageURL = user.profileImageURL
                    isLoading = false
                    
                    // Charger l'image de profil si disponible
                    if let imageURL = user.profileImageURL {
                        loadProfileImage(from: imageURL)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement du profil: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Erreur loadUserProfile: \(error)")
            }
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        Task {
            do {
                guard let url = URL(string: urlString) else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                    }
                }
            } catch {
                print("❌ Erreur loadProfileImage: \(error)")
            }
        }
    }
    
    // MARK: - Update Profile
    
    func updateProfile(name: String, email: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let updatedUser = try await apiService.updateProfile(
                name: name,
                profileImageURL: profileImageURL
            )
            
            await MainActor.run {
                currentUser = updatedUser
                self.name = updatedUser.name
                self.email = updatedUser.email ?? ""
                isLoading = false
                isEditing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur updateProfile: \(error)")
        }
    }
    
    func updateProfileImage(_ image: UIImage) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Convertir l'image en base64
            guard let base64String = imageService.imageToBase64(image) else {
                throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image"])
            }
            
            // Créer une URL de données base64
            let newProfileImageURL = "data:image/jpeg;base64,\(base64String)"
            
            // Sauvegarder l'image localement
            imageService.saveProfileImage(image)
            
            // Mettre à jour le profil avec la nouvelle image
            let updatedUser = try await apiService.updateProfile(
                name: name,
                profileImageURL: newProfileImageURL
            )
            
            await MainActor.run {
                currentUser = updatedUser
                profileImage = image
                profileImageURL = newProfileImageURL
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour de la photo: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur updateProfileImage: \(error)")
        }
    }
    
    func deleteProfileImage() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Supprimer l'image locale
            imageService.deleteProfileImage()
            
            // Mettre à jour le profil avec une URL vide
            let updatedUser = try await apiService.updateProfile(
                name: name,
                profileImageURL: nil
            )
            
            await MainActor.run {
                currentUser = updatedUser
                profileImage = nil
                profileImageURL = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la suppression de la photo: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur deleteProfileImage: \(error)")
        }
    }
    
    // MARK: - Preferences
    
    func loadPreferences() {
        language = userPreferences.getLanguage()
        city = userPreferences.getCity()
        notificationsEnabled = userPreferences.getNotificationsEnabled()
        locationSharingEnabled = userPreferences.getLocationSharingEnabled()
    }
    
    func savePreferences() {
        userPreferences.setLanguage(language)
        userPreferences.setCity(city)
        userPreferences.setNotificationsEnabled(notificationsEnabled)
        userPreferences.setLocationSharingEnabled(locationSharingEnabled)
    }
    
    func setLanguage(_ language: String) {
        self.language = language
        userPreferences.setLanguage(language)
    }
    
    func setCity(_ city: String) {
        self.city = city
        userPreferences.setCity(city)
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        userPreferences.setNotificationsEnabled(enabled)
    }
    
    func setLocationSharingEnabled(_ enabled: Bool) {
        locationSharingEnabled = enabled
        userPreferences.setLocationSharingEnabled(enabled)
    }
    
    // MARK: - Edit Mode
    
    func startEditing() {
        isEditing = true
        // Sauvegarder les valeurs actuelles
        if let user = currentUser {
            name = user.name
            email = user.email ?? ""
        }
    }
    
    func cancelEditing() {
        isEditing = false
        // Restaurer les valeurs originales
        if let user = currentUser {
            name = user.name
            email = user.email ?? ""
        }
    }
    
    func saveChanges() async {
        await updateProfile(name: name, email: email.isEmpty ? nil : email)
        savePreferences()
    }
    
    // MARK: - Validation
    
    func validateName() -> Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func validateEmail() -> Bool {
        if email.isEmpty {
            return true // Email est optionnel
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func canSave() -> Bool {
        return validateName() && validateEmail()
    }
}

