//
//  ChatViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer le chat avec le conducteur
//

import Foundation
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSending: Bool = false
    @Published var rideId: String?
    @Published var driverId: String?
    
    // MARK: - Private Properties
    
    private let realtimeService = RealtimeService.shared
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(rideId: String? = nil, driverId: String? = nil) {
        self.rideId = rideId
        self.driverId = driverId
        setupObservers()
        loadMessages()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les nouveaux messages du RealtimeService
        realtimeService.onChatMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.handleNewMessage(message)
            }
        }
    }
    
    // MARK: - Load Messages
    
    func loadMessages() async {
        guard let rideId = rideId else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let messages = try await apiService.getChatMessages(rideId: rideId)
            
            await MainActor.run {
                self.messages = messages
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des messages: \(error.localizedDescription)"
                isLoading = false
                messages = []
            }
            print("❌ Erreur loadMessages: \(error)")
        }
    }
    
    private func loadMessages() {
        Task {
            await loadMessages()
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ message: String) async -> Bool {
        guard !message.isEmpty, let rideId = rideId else { return false }
        
        await MainActor.run {
            isSending = true
            errorMessage = nil
        }
        
        // Créer un message local (format APIService)
        let chatMessage = ChatMessage(
            id: UUID().uuidString,
            message: message,
            senderId: config.getUserId() ?? "",
            senderName: "Vous",
            timestamp: Date(),
            isFromDriver: false
        )
        
        // Ajouter le message localement
        await MainActor.run {
            messages.append(chatMessage)
            currentMessage = ""
            isSending = false
        }
        
        // Envoyer le message via RealtimeService
        do {
            try await realtimeService.sendChatMessage(rideId: rideId, message: message)
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du message: \(error.localizedDescription)"
                isSending = false
                // Retirer le message en cas d'erreur (seulement si pas déjà ajouté par le serveur)
                // On peut garder le message local car il sera remplacé par celui du serveur
            }
            print("❌ Erreur sendMessage: \(error)")
            return false
        }
    }
    
    // MARK: - Handle New Message
    
    private func handleNewMessage(_ message: ChatMessage) {
        Task { @MainActor in
            // Vérifier si le message n'existe pas déjà
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
                // Trier les messages par timestamp
                messages.sort { $0.timestamp < $1.timestamp }
            }
        }
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(_ messageId: String) async {
        do {
            try await apiService.markMessageAsRead(messageId: messageId)
            
            await MainActor.run {
                // Mettre à jour le statut local si nécessaire
                // Note: Les messages ChatMessage de APIService n'ont pas isRead dans le modèle actuel
                // mais on peut mettre à jour l'interface utilisateur si besoin
            }
        } catch {
            print("❌ Erreur markAsRead: \(error)")
            // Ne pas afficher d'erreur à l'utilisateur pour cette opération silencieuse
        }
    }
}
