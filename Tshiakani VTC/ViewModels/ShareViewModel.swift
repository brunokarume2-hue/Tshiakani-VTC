//
//  ShareViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer le partage de course
//

import Foundation
import SwiftUI
import Combine

class ShareViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var shareLink: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSharing: Bool = false
    @Published var sharedRides: [SharedRide] = []
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Generate Share Link
    
    func generateShareLink(rideId: String) async -> String? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let link = try await apiService.generateShareLink(rideId: rideId)
            
            await MainActor.run {
                shareLink = link
                isLoading = false
            }
            
            return link
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la génération du lien de partage: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur generateShareLink: \(error)")
            return nil
        }
    }
    
    // MARK: - Share Ride
    
    func shareRide(rideId: String, contacts: [String]) async -> Bool {
        await MainActor.run {
            isSharing = true
            errorMessage = nil
        }
        
        // Générer le lien de partage
        guard let link = await generateShareLink(rideId: rideId) else {
            await MainActor.run {
                isSharing = false
            }
            return false
        }
        
        do {
            // Partager avec les contacts via l'API
            try await apiService.shareRide(rideId: rideId, contacts: contacts, link: link)
            
            await MainActor.run {
                isSharing = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du partage: \(error.localizedDescription)"
                isSharing = false
            }
            print("❌ Erreur shareRide: \(error)")
            return false
        }
    }
    
    // MARK: - Share Location
    
    func shareLocation(rideId: String, location: Location) async -> Bool {
        await MainActor.run {
            isSharing = true
            errorMessage = nil
        }
        
        do {
            // Partager la position en temps réel via l'API
            try await apiService.shareLocation(rideId: rideId, location: location)
            
            await MainActor.run {
                isSharing = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du partage de la position: \(error.localizedDescription)"
                isSharing = false
            }
            print("❌ Erreur shareLocation: \(error)")
            return false
        }
    }
    
    // MARK: - Get Shared Rides
    
    func getSharedRides() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let rides = try await apiService.getSharedRides()
            
            await MainActor.run {
                sharedRides = rides
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des courses partagées: \(error.localizedDescription)"
                isLoading = false
                sharedRides = []
            }
            print("❌ Erreur getSharedRides: \(error)")
        }
    }
}

