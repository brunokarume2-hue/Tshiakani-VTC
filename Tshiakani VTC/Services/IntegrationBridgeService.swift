//
//  IntegrationBridgeService.swift
//  Tshiakani VTC
//
//  Service principal d'intégration qui unifie la communication
//  entre l'application iOS et le backend
//  Agit comme un pont (bridge) entre les différents services
//

import Foundation
import Combine

/// Service principal d'intégration (Bridge)
/// Unifie la communication entre iOS et le backend
class IntegrationBridgeService: ObservableObject {
    static let shared = IntegrationBridgeService()
    
    // Services sous-jacents
    private let config = ConfigurationService.shared
    private let socketService = SocketIOService.shared
    private let dataTransform = DataTransformService.shared
    
    // État
    @Published var isConnected: Bool = false
    @Published var connectionState: SocketConnectionState = .disconnected
    
    // Callbacks unifiés
    var onRideRequest: ((Ride) -> Void)?
    var onRideStatusChanged: ((Ride) -> Void)?
    var onDriverLocationUpdate: ((String, Location) -> Void)?
    var onRideAccepted: ((Ride) -> Void)?
    var onRideCancelled: ((String) -> Void)?
    var onConnectionStateChanged: ((SocketConnectionState) -> Void)?
    var onChatMessage: ((ChatMessage) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var currentUserRole: UserRole?
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Configuration
    
    private func setupObservers() {
        // Observer l'état de connexion Socket.io
        socketService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                self?.isConnected = (state == .connected)
                self?.onConnectionStateChanged?(state)
            }
            .store(in: &cancellables)
        
        socketService.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        // Configurer les callbacks Socket.io
        socketService.onRideRequest = { [weak self] ride in
            self?.onRideRequest?(ride)
        }
        
        socketService.onRideStatusChanged = { [weak self] rideId, status in
            // Charger les détails complets de la course depuis l'API si nécessaire
            Task {
                await self?.handleRideStatusChanged(rideId: rideId, status: status)
            }
        }
        
        socketService.onDriverLocationUpdate = { [weak self] driverId, location in
            self?.onDriverLocationUpdate?(driverId, location)
        }
        
        socketService.onRideAccepted = { [weak self] ride in
            self?.onRideAccepted?(ride)
        }
        
        socketService.onRideCancelled = { [weak self] rideId in
            self?.onRideCancelled?(rideId)
        }
        
        socketService.onChatMessage = { [weak self] message in
            self?.onChatMessage?(message)
        }
        
        socketService.onConnected = { [weak self] in
            print("✅ IntegrationBridge: Connecté au backend")
            // Rejoindre les rooms nécessaires après connexion
            self?.joinNecessaryRooms()
        }
        
        socketService.onDisconnected = {
            print("⚠️ IntegrationBridge: Déconnecté du backend")
        }
        
        socketService.onError = { error in
            print("❌ IntegrationBridge: Erreur: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Connexion
    
    /// Se connecte au backend (API + WebSocket)
    func connect(userId: String? = nil, userRole: UserRole? = nil) {
        let userId = userId ?? config.getUserId()
        let userRole = userRole ?? config.getUserRole()
        
        guard let userId = userId, let userRole = userRole else {
            print("⚠️ IntegrationBridge: Impossible de se connecter sans userId et userRole")
            return
        }
        
        self.currentUserId = userId
        self.currentUserRole = userRole
        
        // Se connecter au WebSocket
        let namespace = userRole == .driver ? config.driverSocketNamespace : nil
        let authToken = config.getAuthToken()
        
        socketService.connect(namespace: namespace, authToken: authToken)
    }
    
    /// Se déconnecte du backend
    func disconnect() {
        socketService.disconnect()
        currentUserId = nil
        currentUserRole = nil
    }
    
    /// Rejoint les rooms nécessaires après connexion
    private func joinNecessaryRooms() {
        guard let userId = currentUserId, let userRole = currentUserRole else {
            return
        }
        
        switch userRole {
        case .driver:
            // Le driver rejoint sa room personnelle
            socketService.joinRoom("driver:\(userId)")
            
        case .client:
            // Le client peut rejoindre ses courses actives si nécessaire
            // Ceci sera fait dynamiquement quand une course est créée
            break
            
        case .admin:
            // L'admin peut écouter toutes les courses
            socketService.joinRoom("admin:all")
        }
    }
    
    // MARK: - Gestion des courses
    
    /// Rejoint la room d'une course pour recevoir les mises à jour
    func joinRideRoom(_ rideId: String) {
        socketService.joinRoom("ride:\(rideId)")
    }
    
    /// Quitte la room d'une course
    func leaveRideRoom(_ rideId: String) {
        socketService.leaveRoom("ride:\(rideId)")
    }
    
    /// Émet un événement de mise à jour de statut de course
    func emitRideStatusUpdate(rideId: String, status: RideStatus) {
        socketService.emit(event: "ride:status:update", data: [
            "rideId": rideId,
            "status": status.rawValue
        ])
    }
    
    /// Charge les détails d'une course après changement de statut
    private func handleRideStatusChanged(rideId: String, status: String) async {
        // Optionnel: Charger les détails complets depuis l'API
        // Pour l'instant, on utilise juste les données du message Socket.io
        // Cette méthode peut être étendue pour charger plus de détails si nécessaire
    }
    
    // MARK: - Gestion de la position du driver
    
    /// Met à jour la position du driver en temps réel
    func updateDriverLocation(driverId: String, location: Location) {
        let locationData = dataTransform.locationToBackend(location)
        
        socketService.emit(event: "driver:location", data: [
            "driverId": driverId,
            "location": locationData
        ])
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Vérifie si le service est configuré et prêt
    func isReady() -> Bool {
        return config.getAuthToken() != nil &&
               config.getUserId() != nil &&
               config.getUserRole() != nil
    }
    
    /// Réinitialise la connexion
    func reconnect() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connect()
        }
    }
    
    // MARK: - Gestion de l'authentification
    
    /// Configure l'authentification après connexion
    func setAuthentication(userId: String, userRole: UserRole, token: String) {
        config.setUserId(userId)
        config.setUserRole(userRole)
        config.setAuthToken(token)
        
        self.currentUserId = userId
        self.currentUserRole = userRole
        
        // Se reconnecter avec les nouvelles credentials
        reconnect()
    }
    
    /// Efface l'authentification
    func clearAuthentication() {
        config.setUserId(nil)
        config.setUserRole(nil)
        config.setAuthToken(nil)
        
        disconnect()
    }
    
    // MARK: - Chat
    
    /// Envoie un message de chat
    func sendChatMessage(rideId: String, message: String) {
        socketService.emit(event: "chat:message", data: [
            "rideId": rideId,
            "message": message,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
}

