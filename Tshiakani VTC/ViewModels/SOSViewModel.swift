//
//  SOSViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer les alertes SOS/Urgence
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class SOSViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isSOSActive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentLocation: Location?
    @Published var emergencyContacts: [EmergencyContact] = []
    
    // MARK: - Private Properties
    
    private let sosService = SOSService.shared
    private let apiService = APIService.shared
    private let locationService = LocationService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        loadEmergencyContacts()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer la position actuelle
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Emergency Contacts
    
    func loadEmergencyContacts() {
        // Charger depuis UserDefaults
        if let data = UserDefaults.standard.data(forKey: "emergency_contacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = contacts
        } else {
            // Contacts d'urgence par défaut
            emergencyContacts = [
                EmergencyContact(
                    id: "1",
                    name: "Police",
                    phoneNumber: "113",
                    type: .police
                ),
                EmergencyContact(
                    id: "2",
                    name: "Ambulance",
                    phoneNumber: "118",
                    type: .ambulance
                ),
                EmergencyContact(
                    id: "3",
                    name: "Pompiers",
                    phoneNumber: "115",
                    type: .fire
                )
            ]
        }
    }
    
    // MARK: - Activate SOS
    
    func activateSOS(message: String? = nil) async -> Bool {
        guard let location = currentLocation ?? locationService.currentLocation else {
            await MainActor.run {
                errorMessage = "Impossible de récupérer votre position"
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            // Envoyer l'alerte SOS via l'API
            try await apiService.sendSOSAlert(location: location, message: message)
            
            // Activer le service SOS local
            await sosService.activateSOS(location: location)
            
            await MainActor.run {
                isSOSActive = true
                successMessage = "Alerte SOS activée"
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'activation de l'alerte SOS: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur activateSOS: \(error)")
            return false
        }
    }
    
    // MARK: - Deactivate SOS
    
    func deactivateSOS() async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Désactiver l'alerte SOS via l'API
            try await apiService.deactivateSOSAlert()
            
            // Désactiver le service SOS local
            await sosService.deactivateSOS()
            
            await MainActor.run {
                isSOSActive = false
                successMessage = "Alerte SOS désactivée"
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la désactivation de l'alerte SOS: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur deactivateSOS: \(error)")
            return false
        }
    }
    
    // MARK: - Call Emergency Contact
    
    func callEmergencyContact(_ contact: EmergencyContact) {
        let phoneNumber = contact.phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
            }
            #endif
        }
    }
    
    // MARK: - Add Emergency Contact
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    // MARK: - Remove Emergency Contact
    
    func removeEmergencyContact(_ contactId: String) {
        emergencyContacts.removeAll { $0.id == contactId }
        saveEmergencyContacts()
    }
    
    // MARK: - Save Emergency Contacts
    
    private func saveEmergencyContacts() {
        if let data = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(data, forKey: "emergency_contacts")
        }
    }
}

// MARK: - Emergency Contact Model

struct EmergencyContact: Identifiable, Codable {
    let id: String
    let name: String
    let phoneNumber: String
    let type: EmergencyContactType
}

enum EmergencyContactType: String, Codable {
    case police = "police"
    case ambulance = "ambulance"
    case fire = "fire"
    case custom = "custom"
}
