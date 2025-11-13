//
//  FavoritesViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les adresses favorites
//

import Foundation
import SwiftUI
import Combine

class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var favoriteAddresses: [SavedAddress] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFavorite: SavedAddress?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadFavorites()
    }
    
    // MARK: - Load Favorites
    
    func loadFavorites() {
        isLoading = true
        errorMessage = nil
        
        // Charger depuis UserDefaults (pour affichage immédiat)
        if let data = UserDefaults.standard.data(forKey: "favorite_addresses"),
           let addresses = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            favoriteAddresses = addresses.filter { $0.isFavorite }
            isLoading = false
        } else {
            favoriteAddresses = []
            isLoading = false
        }
        
        // Charger depuis le backend (pour synchronisation)
        Task {
            await loadFavoritesFromBackend()
        }
    }
    
    private func loadFavoritesFromBackend() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let addresses = try await apiService.getFavoriteAddresses()
            await MainActor.run {
                favoriteAddresses = addresses.filter { $0.isFavorite }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des favoris: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur loadFavoritesFromBackend: \(error)")
        }
    }
    
    // MARK: - Add Favorite
    
    func addFavorite(_ address: SavedAddress) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var favoriteAddress = address
        favoriteAddress.isFavorite = true
        
        // Ajouter aux favoris locaux
        await MainActor.run {
            if !favoriteAddresses.contains(where: { $0.id == favoriteAddress.id }) {
                favoriteAddresses.append(favoriteAddress)
            }
            isLoading = false
        }
        
        // Sauvegarder dans UserDefaults
        saveFavoritesToLocalStorage()
        
        // Sauvegarder sur le backend
        do {
            try await apiService.addFavoriteAddress(favoriteAddress)
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'ajout du favori: \(error.localizedDescription)"
                // Ne pas retirer le favori local en cas d'erreur, il sera synchronisé plus tard
            }
            print("❌ Erreur addFavorite (backend): \(error)")
        }
        
        return true
    }
    
    // MARK: - Remove Favorite
    
    func removeFavorite(_ address: SavedAddress) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Retirer des favoris locaux
        await MainActor.run {
            favoriteAddresses.removeAll { $0.id == address.id }
            isLoading = false
        }
        
        // Sauvegarder dans UserDefaults
        saveFavoritesToLocalStorage()
        
        // Retirer du backend
        do {
            try await apiService.removeFavoriteAddress(address.id)
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la suppression du favori: \(error.localizedDescription)"
                // Remettre le favori local en cas d'erreur
                if !favoriteAddresses.contains(where: { $0.id == address.id }) {
                    favoriteAddresses.append(address)
                }
            }
            print("❌ Erreur removeFavorite (backend): \(error)")
            return false
        }
        
        return true
    }
    
    // MARK: - Toggle Favorite
    
    func toggleFavorite(_ address: SavedAddress) async {
        if address.isFavorite {
            await removeFavorite(address)
        } else {
            await addFavorite(address)
        }
    }
    
    // MARK: - Save to Local Storage
    
    private func saveFavoritesToLocalStorage() {
        // Charger toutes les adresses sauvegardées
        var allAddresses: [SavedAddress] = []
        if let data = UserDefaults.standard.data(forKey: "saved_addresses"),
           let addresses = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            allAddresses = addresses
        }
        
        // Mettre à jour le statut favori
        for (index, address) in allAddresses.enumerated() {
            if favoriteAddresses.contains(where: { $0.id == address.id }) {
                allAddresses[index].isFavorite = true
            } else {
                allAddresses[index].isFavorite = false
            }
        }
        
        // Sauvegarder
        if let data = try? JSONEncoder().encode(allAddresses) {
            UserDefaults.standard.set(data, forKey: "saved_addresses")
        }
    }
    
    // MARK: - Use Favorite
    
    func useFavorite(_ address: SavedAddress) {
        selectedFavorite = address
    }
}
