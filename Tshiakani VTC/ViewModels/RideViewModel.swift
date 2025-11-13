//
//  RideViewModel.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//
//  NOTE: Ce fichier utilise les types suivants du même module :
//  - Ride, RideStatus (Models/Ride.swift)
//  - User, UserRole (Models/User.swift)
//  - Location (Models/Location.swift)
//  - APIService (Services/APIService.swift)
//  - LocationService (Services/LocationService.swift)
//  - PaymentService (Services/PaymentService.swift)
//  - RealtimeService (Services/RealtimeService.swift)
//  - NotificationService (Services/NotificationService.swift)
//
//  Tous ces types sont accessibles sans import car ils font partie du même module Swift.
//  Si vous voyez des erreurs dans le linter, elles disparaîtront lors de la compilation dans Xcode.

import Foundation
import SwiftUI
import Combine

class RideViewModel: ObservableObject {
    @Published var currentRide: Ride?
    @Published var rideHistory: [Ride] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableDrivers: [User] = []
    
    private let apiService = APIService.shared
    private let locationService = LocationService.shared
    private let paymentService = PaymentService.shared
    private let realtimeService = RealtimeService.shared
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserId: String?
    
    init() {
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Écouter les changements de statut de course
        realtimeService.onRideStatusChanged = { [weak self] (ride: Ride) in
            DispatchQueue.main.async {
                if self?.currentRide?.id == ride.id {
                    self?.currentRide = ride
                    
                    // Notifier selon le statut
                    switch ride.status {
                    case .accepted:
                        self?.notificationService.notifyRideAccepted(ride: ride, driverName: "Conducteur")
                    case .driverArriving:
                        self?.notificationService.notifyDriverArriving(ride: ride, driverName: "Conducteur")
                    case .completed:
                        self?.notificationService.notifyRideCompleted(ride: ride)
                    case .cancelled:
                        self?.notificationService.notifyRideCancelled(ride: ride)
                    default:
                        break
                    }
                }
            }
        }
        
        // Écouter les acceptations de course
        realtimeService.onRideAccepted = { [weak self] (ride: Ride) in
            DispatchQueue.main.async {
                if self?.currentRide?.id == ride.id {
                    self?.currentRide = ride
                }
            }
        }
        
        // Écouter les annulations
        realtimeService.onRideCancelled = { [weak self] (rideId: String) in
            DispatchQueue.main.async {
                if self?.currentRide?.id == rideId {
                    self?.currentRide = nil
                }
            }
        }
    }
    
    func requestRide(pickup: Location, dropoff: Location, userId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard !userId.isEmpty else {
            await MainActor.run {
                errorMessage = "Vous devez être connecté"
                isLoading = false
            }
            return
        }
        
        let distance = pickup.distance(to: dropoff)
        
        // 🧠 Le prix sera calculé par le backend avec l'algorithme IA
        // On crée un ride temporaire avec un prix de 0, le backend le calculera
        let ride = Ride(
            clientId: userId,
            pickupLocation: pickup,
            dropoffLocation: dropoff,
            status: RideStatus.pending,
            estimatedPrice: 0, // Sera calculé par le backend
            distance: distance
        )
        
        do {
            // Le backend calcule le prix avec IA et assigne automatiquement le meilleur chauffeur
            let createdRide = try await apiService.createRide(ride)
            
            await MainActor.run {
                currentRide = createdRide
                isLoading = false
            }
            
            // Envoyer la demande via le service temps réel
            try await realtimeService.sendRideRequest(createdRide)
            
            // Se connecter au service temps réel si pas déjà connecté
            realtimeService.connect(userId: userId, userRole: UserRole.client)
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création de la course: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func cancelRide() async {
        guard let ride = currentRide else { return }
        
        do {
            // Annuler via le backend API
            let updatedRide = try await apiService.updateRideStatus(ride.id, status: RideStatus.cancelled)
            await MainActor.run {
                currentRide = updatedRide
                // Nettoyer la course actuelle après annulation
                // pour permettre de créer une nouvelle course
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.currentRide = nil
                }
            }
            
            // Notifier via le service temps réel
            try? await realtimeService.cancelRide(ride.id)
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'annulation: \(error.localizedDescription)"
                // Nettoyer quand même la course en cas d'erreur
                currentRide = nil
            }
        }
    }
    
    /// Trouve les chauffeurs disponibles près d'une localisation
    func findAvailableDrivers(near location: Location, radius: Double = 5.0) async {
        do {
            let drivers = try await apiService.getAvailableDrivers(
                latitude: location.latitude,
                longitude: location.longitude,
                radius: radius
            )
            await MainActor.run {
                availableDrivers = drivers
            }
        } catch {
            print("Erreur lors de la recherche de chauffeurs: \(error.localizedDescription)")
            await MainActor.run {
                availableDrivers = []
            }
        }
    }
    
    // MARK: - Ride Tracking
    
    /// Charge les détails d'une course pour le suivi
    func loadRideDetails(rideId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ride = try await apiService.getRideDetails(rideId: rideId)
            
            await MainActor.run {
                currentRide = ride
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des détails de la course: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur loadRideDetails: \(error)")
        }
    }
    
    /// Suit la position du chauffeur en temps réel
    func trackDriver(rideId: String) async -> (driverId: String, driverName: String, location: Location, status: String, estimatedArrivalMinutes: Int?)? {
        do {
            let trackingInfo = try await apiService.trackDriver(rideId: rideId)
            
            // Mettre à jour la position du chauffeur dans la course actuelle
            if let ride = currentRide, ride.id == rideId {
                var updatedRide = ride
                updatedRide.driverLocation = trackingInfo.location
                await MainActor.run {
                    currentRide = updatedRide
                }
            }
            
            return trackingInfo
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du suivi du conducteur: \(error.localizedDescription)"
            }
            print("❌ Erreur trackDriver: \(error)")
            return nil
        }
    }
    
    // MARK: - Ride History
    
    /// Charge l'historique des courses avec gestion d'erreurs améliorée
    func loadRideHistory(userId: String) async {
        guard !userId.isEmpty else {
            await MainActor.run {
                errorMessage = "Vous devez être connecté"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let history = try await apiService.getRideHistory(for: userId)
            
            await MainActor.run {
                rideHistory = history
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement de l'historique: \(error.localizedDescription)"
                isLoading = false
                rideHistory = []
            }
            print("❌ Erreur loadRideHistory: \(error)")
        }
    }
    
    /// Charge une course spécifique depuis l'historique
    func loadRideFromHistory(rideId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ride = try await apiService.getRideDetails(rideId: rideId)
            
            await MainActor.run {
                currentRide = ride
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement de la course: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur loadRideFromHistory: \(error)")
        }
    }
    
    // MARK: - Rating
    
    /// Évalue une course
    func rateRide(rideId: String, rating: Int, review: String?) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.rateRide(rideId, rating: rating, comment: review)
            
            // Mettre à jour la course actuelle
            if var ride = currentRide, ride.id == rideId {
                ride.rating = rating
                ride.review = review
                await MainActor.run {
                    currentRide = ride
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'évaluation: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur rateRide: \(error)")
            return false
        }
    }
    
    // MARK: - Driver Location Updates
    
    /// Écoute les mises à jour de position du chauffeur en temps réel
    func startTrackingDriverLocation(rideId: String) {
        // Écouter les mises à jour via RealtimeService
        realtimeService.onDriverLocationUpdated = { [weak self] (ride: Ride, location: Location) in
            DispatchQueue.main.async {
                if ride.id == rideId {
                    var updatedRide = ride
                    updatedRide.driverLocation = location
                    self?.currentRide = updatedRide
                }
            }
        }
    }
    
    func stopTrackingDriverLocation() {
        realtimeService.onDriverLocationUpdated = nil
    }
}

