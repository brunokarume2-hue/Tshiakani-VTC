//
//  SocketIOService.swift
//  Tshiakani VTC
//
//  Service de communication WebSocket avec le backend Socket.io
//  Gère les connexions, reconnexions automatiques, et événements en temps réel
//

import Foundation
import Combine

/// Types d'événements Socket.io
enum SocketEvent: String {
    case connect = "connect"
    case disconnect = "disconnect"
    case error = "error"
    case rideRequest = "ride_request"
    case rideStatusChanged = "ride:status:changed"
    case driverLocationUpdate = "driver:location:update"
    case rideAccepted = "ride:accepted"
    case rideCancelled = "ride:cancelled"
    case ping = "ping"
    case pong = "pong"
}

/// État de la connexion WebSocket
enum SocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)
    
    static func == (lhs: SocketConnectionState, rhs: SocketConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.reconnecting, .reconnecting):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Service de communication WebSocket/Socket.io
class SocketIOService: NSObject, ObservableObject {
    static let shared = SocketIOService()
    
    @Published var connectionState: SocketConnectionState = .disconnected
    @Published var isConnected: Bool = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private var shouldReconnect = true
    
    private let config = ConfigurationService.shared
    private let dataTransform = DataTransformService.shared
    
    // Callbacks pour les événements
    var onRideRequest: ((Ride) -> Void)?
    var onRideStatusChanged: ((String, String) -> Void)? // rideId, status
    var onDriverLocationUpdate: ((String, Location) -> Void)? // driverId, location
    var onRideAccepted: ((Ride) -> Void)?
    var onRideCancelled: ((String) -> Void)? // rideId
    var onChatMessage: ((ChatMessage) -> Void)? // message de chat
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    private var messageQueue: [String] = []
    
    override private init() {
        super.init()
    }
    
    // MARK: - Connexion
    
    /// Se connecte au serveur WebSocket
    func connect(namespace: String? = nil, authToken: String? = nil) {
        guard connectionState != .connected && connectionState != .connecting else {
            print("⚠️ Déjà connecté ou en cours de connexion")
            return
        }
        
        connectionState = .connecting
        shouldReconnect = true
        reconnectAttempts = 0
        
        var urlString = config.buildSocketURL(namespace: namespace)
        
        // Ajouter le token d'authentification si fourni
        if let token = authToken ?? config.getAuthToken() {
            urlString += "?token=\(token)"
        }
        
        guard let url = URL(string: urlString) else {
            let errorMessage = "URL invalide: \(urlString)"
            let error = NSError(domain: "SocketIOService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            connectionState = .error(errorMessage)
            onError?(error)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        urlSession = session
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
        startPingTimer()
        
        print("🔌 Tentative de connexion WebSocket à \(urlString)")
    }
    
    /// Se déconnecte du serveur WebSocket
    func disconnect() {
        shouldReconnect = false
        stopPingTimer()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        
        connectionState = .disconnected
        isConnected = false
        reconnectAttempts = 0
        
        onDisconnected?()
        print("🔌 Déconnexion WebSocket")
    }
    
    // MARK: - Envoi de messages
    
    /// Envoie un événement Socket.io
    func emit(event: String, data: [String: Any]) {
        guard isConnected else {
            // Mettre en file d'attente le message
            if let jsonData = try? JSONSerialization.data(withJSONObject: ["event": event, "data": data]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                messageQueue.append(jsonString)
            }
            return
        }
        
        let message: [String: Any] = [
            "event": event,
            "data": data
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Erreur sérialisation message Socket.io")
            return
        }
        
        let socketMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(socketMessage) { error in
            if let error = error {
                print("❌ Erreur envoi message Socket.io: \(error)")
                self.onError?(error)
            }
        }
    }
    
    /// Rejoint une room Socket.io
    func joinRoom(_ room: String) {
        emit(event: "join", data: ["room": room])
    }
    
    /// Quitte une room Socket.io
    func leaveRoom(_ room: String) {
        emit(event: "leave", data: ["room": room])
    }
    
    // MARK: - Réception de messages
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continuer à écouter les messages
                self.receiveMessage()
                
            case .failure(let error):
                print("❌ Erreur réception message WebSocket: \(error)")
                self.handleDisconnection(error: error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let message = dataTransform.parseSocketMessage(data) else {
            return
        }
        
        // Gérer les événements Socket.io
        if let event = message["event"] as? String {
            handleSocketEvent(event, data: message["data"] as? [String: Any] ?? [:])
        } else if let type = message["type"] as? String {
            // Format alternatif avec "type" au lieu de "event"
            handleSocketEvent(type, data: message)
        } else {
            // Message simple, essayer de le parser comme un événement direct
            handleSocketEvent("message", data: message)
        }
    }
    
    private func handleSocketEvent(_ event: String, data: [String: Any]) {
        switch event {
        case "connect", "connected":
            handleConnect()
            
        case "disconnect":
            handleDisconnect()
            
        case "error":
            if let errorMessage = data["message"] as? String {
                let error = NSError(domain: "SocketIOService", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                onError?(error)
            }
            
        case "ride_request":
            handleRideRequest(data)
            
        case "ride:status:changed":
            handleRideStatusChanged(data)
            
        case "driver:location:update":
            handleDriverLocationUpdate(data)
            
        case "ride:accepted":
            handleRideAccepted(data)
            
        case "ride:cancelled":
            handleRideCancelled(data)
            
        case "chat:message":
            handleChatMessage(data)
            
        case "pong":
            // Réponse au ping, ne rien faire
            break
            
        default:
            print("📨 Événement Socket.io non géré: \(event)")
        }
    }
    
    private func handleChatMessage(_ data: [String: Any]) {
        // Récupérer l'ID avec valeur par défaut
        let id = (data["id"] as? String) ?? UUID().uuidString
        
        guard let message = data["message"] as? String,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let timestampString = data["timestamp"] as? String else {
            return
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.date(from: timestampString) ?? Date()
        let isFromDriver = data["isFromDriver"] as? Bool ?? false
        
        let chatMessage = ChatMessage(
            id: id,
            message: message,
            senderId: senderId,
            senderName: senderName,
            timestamp: timestamp,
            isFromDriver: isFromDriver
        )
        
        onChatMessage?(chatMessage)
    }
    
    // MARK: - Gestion des événements
    
    private func handleConnect() {
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.isConnected = true
            self.reconnectAttempts = 0
            self.onConnected?()
            
            // Envoyer les messages en file d'attente
            self.sendQueuedMessages()
            
            print("✅ Connecté au serveur WebSocket")
        }
    }
    
    private func handleDisconnect() {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.isConnected = false
            self.onDisconnected?()
            print("🔌 Déconnecté du serveur WebSocket")
        }
    }
    
    private func handleRideRequest(_ data: [String: Any]) {
        guard let rideData = data["ride"] as? [String: Any],
              let ride = dataTransform.rideFromBackend(rideData) else {
            return
        }
        onRideRequest?(ride)
    }
    
    private func handleRideStatusChanged(_ data: [String: Any]) {
        guard let rideId = data["rideId"] as? String ?? (data["rideId"] as? Int).map({ String($0) }),
              let status = data["status"] as? String else {
            return
        }
        onRideStatusChanged?(rideId, status)
    }
    
    private func handleDriverLocationUpdate(_ data: [String: Any]) {
        guard let driverId = data["driverId"] as? String ?? (data["driverId"] as? Int).map({ String($0) }),
              let locationData = data["location"] as? [String: Any],
              let latitude = locationData["latitude"] as? Double,
              let longitude = locationData["longitude"] as? Double else {
            return
        }
        
        let location = Location(
            latitude: latitude,
            longitude: longitude,
            address: locationData["address"] as? String,
            timestamp: Date()
        )
        
        // Vérifier si c'est pour une course active (rideId présent)
        if let rideId = data["rideId"] as? String ?? (data["rideId"] as? Int).map({ String($0) }) {
            print("�� Position du chauffeur reçue pour la course \(rideId)")
        }
        
        onDriverLocationUpdate?(driverId, location)
    }
    
    private func handleRideAccepted(_ data: [String: Any]) {
        guard let ride = dataTransform.rideFromBackend(data) else {
            return
        }
        onRideAccepted?(ride)
    }
    
    private func handleRideCancelled(_ data: [String: Any]) {
        guard let rideId = data["rideId"] as? String ?? (data["rideId"] as? Int).map({ String($0) }) else {
            return
        }
        onRideCancelled?(rideId)
    }
    
    // MARK: - Reconnexion automatique
    
    private func handleDisconnection(error: Error? = nil) {
        guard shouldReconnect else {
            return
        }
        
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.isConnected = false
            self.stopPingTimer()
            
            if self.reconnectAttempts < self.config.socketMaxReconnectAttempts {
                self.connectionState = .reconnecting
                self.scheduleReconnect()
            } else {
                let errorMessage = error?.localizedDescription ?? "Impossible de se reconnecter après \(self.config.socketMaxReconnectAttempts) tentatives"
                let finalError = error ?? NSError(domain: "SocketIOService", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                self.connectionState = .error(errorMessage)
                self.onError?(finalError)
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectAttempts += 1
        let delay = config.socketReconnectInterval * Double(reconnectAttempts)
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
        
        print("🔄 Tentative de reconnexion \(reconnectAttempts)/\(config.socketMaxReconnectAttempts) dans \(delay)s")
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Ping/Pong (Keep-alive)
    
    private func startPingTimer() {
        stopPingTimer()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: config.socketPingInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        emit(event: "ping", data: [:])
    }
    
    // MARK: - File d'attente des messages
    
    private func sendQueuedMessages() {
        let queue = messageQueue
        messageQueue.removeAll()
        
        for message in queue {
            if let data = message.data(using: .utf8),
               let messageDict = dataTransform.parseSocketMessage(data) {
                if let event = messageDict["event"] as? String,
                   let data = messageDict["data"] as? [String: Any] {
                    emit(event: event, data: data)
                }
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension SocketIOService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        handleConnect()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) }
        print("🔌 WebSocket fermé: \(closeCode), raison: \(reasonString ?? "inconnue")")
        handleDisconnection()
    }
}

