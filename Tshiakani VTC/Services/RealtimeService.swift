//
//  RealtimeService.swift
//  Tshiakani VTC
//
//  Service de communication en temps réel entre Client, Driver et Backend
//  Utilise SocketIOService pour les mises à jour instantanées via WebSocket
//

import Foundation
import Combine

/// Service de communication en temps réel
/// Utilise SocketIOService (WebSocket) pour les mises à jour instantanées
class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    @Published var activeRides: [Ride] = []
    @Published var connectedDrivers: [User] = []
    @Published var isConnected = false
    
    private var cancellables = Set<AnyCancellable>()
    private let bridge = IntegrationBridgeService.shared
    private let apiService = APIService.shared
    private var currentUserId: String?
    private var currentUserRole: UserRole?
    
    // Callbacks pour les événements
    var onRideStatusChanged: ((Ride) -> Void)?
    var onNewRideRequest: ((Ride) -> Void)?
    var onDriverLocationUpdated: ((Ride, Location) -> Void)? // ride, location
    var onRideAccepted: ((Ride) -> Void)?
    var onRideCancelled: ((String) -> Void)? // rideId
    var onChatMessage: ((ChatMessage) -> Void)? // message de chat
    
    private init() {
        setupBridgeObservers()
    }
    
    // MARK: - Configuration
    
    private func setupBridgeObservers() {
        // Observer l'état de connexion
        bridge.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        // Configurer les callbacks du bridge
        bridge.onRideRequest = { [weak self] ride in
            DispatchQueue.main.async {
                self?.handleNewRide(ride)
            }
        }
        
        bridge.onRideStatusChanged = { [weak self] ride in
            DispatchQueue.main.async {
                self?.handleRideUpdate(ride)
            }
        }
        
        bridge.onDriverLocationUpdate = { [weak self] driverId, location in
            DispatchQueue.main.async {
                // Trouver la course associée au conducteur
                if let ride = self?.activeRides.first(where: { $0.driverId == driverId }) {
                    self?.onDriverLocationUpdated?(ride, location)
                }
            }
        }
        
        bridge.onChatMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.onChatMessage?(message)
            }
        }
        
        bridge.onRideAccepted = { [weak self] ride in
            DispatchQueue.main.async {
                self?.handleRideAccepted(ride)
            }
        }
        
        bridge.onRideCancelled = { [weak self] rideId in
            DispatchQueue.main.async {
                self?.handleRideCancelled(rideId)
            }
        }
    }
    
    // MARK: - Connexion
    
    func connect(userId: String, userRole: UserRole) {
        currentUserId = userId
        currentUserRole = userRole
        
        // Se connecter via le bridge
        bridge.connect(userId: userId, userRole: userRole)
    }
    
    func disconnect() {
        bridge.disconnect()
        currentUserId = nil
        currentUserRole = nil
        activeRides.removeAll()
        connectedDrivers.removeAll()
    }
    
    // MARK: - Gestion des courses
    
    private func handleNewRide(_ ride: Ride) {
        if ride.status == .pending {
            onNewRideRequest?(ride)
        }
        
        // Ajouter ou mettre à jour la course
        if let index = activeRides.firstIndex(where: { $0.id == ride.id }) {
            activeRides[index] = ride
        } else {
            activeRides.append(ride)
        }
        
        // Rejoindre la room de la course pour recevoir les mises à jour
        bridge.joinRideRoom(ride.id)
    }
    
    private func handleRideUpdate(_ ride: Ride) {
        // Mettre à jour la course dans la liste
        if let index = activeRides.firstIndex(where: { $0.id == ride.id }) {
            activeRides[index] = ride
        } else {
            activeRides.append(ride)
        }
        
        // Notifier le callback
        onRideStatusChanged?(ride)
        
        // Gérer les événements spécifiques selon le statut
        switch ride.status {
        case .accepted:
            onRideAccepted?(ride)
        case .cancelled:
            onRideCancelled?(ride.id)
        default:
            break
        }
    }
    
    private func handleRideAccepted(_ ride: Ride) {
        onRideAccepted?(ride)
        handleRideUpdate(ride)
    }
    
    private func handleRideCancelled(_ rideId: String) {
        activeRides.removeAll { $0.id == rideId }
        onRideCancelled?(rideId)
        
        // Quitter la room de la course
        bridge.leaveRideRoom(rideId)
    }
    
    // MARK: - Émission d'événements
    
    /// Client envoie une demande de course
    func sendRideRequest(_ ride: Ride) async throws {
        guard isConnected else {
            throw NSError(domain: "RealtimeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])
        }
        
        // La création de la course se fait via l'API
        // Le backend émet automatiquement l'événement Socket.io "ride_request"
        // après la création de la course
        
        // Rejoindre la room de la course pour recevoir les mises à jour
        bridge.joinRideRoom(ride.id)
    }
    
    /// Driver accepte une course
    func acceptRide(_ rideId: String, driverId: String) async throws {
        guard isConnected else {
            throw NSError(domain: "RealtimeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])
        }
        
        // Mettre à jour le statut via l'API
        let updatedRide = try await apiService.updateRideStatus(rideId, status: .accepted)
        
        // Émettre l'événement Socket.io
        bridge.emitRideStatusUpdate(rideId: rideId, status: .accepted)
        
        // Mettre à jour la course locale
        handleRideUpdate(updatedRide)
    }
    
    /// Driver refuse une course
    func rejectRide(_ rideId: String, driverId: String) {
        // Le driver refuse - la course reste disponible pour d'autres drivers
        // Pas besoin de mettre à jour la base de données
        // Juste quitter la room si nécessaire
    }
    
    /// Mettre à jour le statut d'une course
    func updateRideStatus(rideId: String, status: RideStatus, driverId: String? = nil) async throws {
        guard isConnected else {
            throw NSError(domain: "RealtimeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])
        }
        
        // Mettre à jour via l'API
        let updatedRide = try await apiService.updateRideStatus(rideId, status: status)
        
        // Émettre l'événement Socket.io
        bridge.emitRideStatusUpdate(rideId: rideId, status: status)
        
        // Mettre à jour la course locale
        handleRideUpdate(updatedRide)
    }
    
    /// Mettre à jour la position du driver
    func updateDriverLocation(driverId: String, location: Location) async throws {
        guard isConnected else {
            throw NSError(domain: "RealtimeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])
        }
        
        // Mettre à jour via le bridge
        bridge.updateDriverLocation(driverId: driverId, location: location)
    }
    
    /// Client annule une course
    func cancelRide(_ rideId: String) async throws {
        guard isConnected else {
            throw NSError(domain: "RealtimeService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])
        }
        
        // Annuler via l'API
        try await updateRideStatus(rideId: rideId, status: .cancelled)
        
        // Quitter la room de la course
        bridge.leaveRideRoom(rideId)
    }
    
    // MARK: - Chargement des courses
    
    /// Charge les courses actives pour l'utilisateur
    func loadActiveRides(userId: String, userRole: UserRole) async {
        do {
            // Charger l'historique depuis l'API
            let history = try await apiService.getRideHistory(for: userId)
            
            // Filtrer les courses actives (non terminées, non annulées)
            let active = history.filter { ride in
                ride.status != .completed && ride.status != .cancelled
            }
            
            await MainActor.run {
                activeRides = active
                
                // Rejoindre les rooms des courses actives
                for ride in active {
                    bridge.joinRideRoom(ride.id)
                }
            }
        } catch {
            print("Erreur lors du chargement des courses actives: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Chat
    
    /// Envoie un message de chat
    func sendChatMessage(rideId: String, message: String) async throws {
        // Envoyer le message via l'API HTTP pour qu'il soit sauvegardé en base de données
        try await apiService.sendChatMessage(rideId: rideId, message: message)
        
        // Émettre aussi via Socket.io pour la transmission en temps réel
        if isConnected {
            bridge.sendChatMessage(rideId: rideId, message: message)
        }
    }
}
