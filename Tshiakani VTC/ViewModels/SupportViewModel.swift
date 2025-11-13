//
//  SupportViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer le support client
//

import Foundation
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

class SupportViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var supportMessages: [SupportMessage] = []
    @Published var currentMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSending: Bool = false
    
    // FAQ
    @Published var faqItems: [FAQItem] = []
    @Published var expandedFAQItem: String?
    
    // Support tickets
    @Published var supportTickets: [SupportTicket] = []
    
    // Success message
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let config = ConfigurationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadFAQ()
    }
    
    // MARK: - FAQ
    
    func loadFAQ() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            do {
                let fetchedFaq = try await apiService.getFAQ()
                await MainActor.run {
                    faqItems = fetchedFaq
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement de la FAQ: \(error.localizedDescription)"
                    isLoading = false
                    // Utiliser la FAQ statique en cas d'erreur
                    faqItems = [
                        FAQItem(
                            id: "1",
                            question: "Comment commander une course ?",
                            answer: "Pour commander une course, ouvrez l'application, entrez votre destination, sélectionnez votre point de départ, et confirmez votre réservation."
                        ),
                        FAQItem(
                            id: "2",
                            question: "Quels sont les moyens de paiement acceptés ?",
                            answer: "Nous acceptons les paiements en espèces, mobile money (Orange Money, M-Pesa, Airtel Money), et les cartes bancaires via Stripe."
                        ),
                        FAQItem(
                            id: "3",
                            question: "Comment annuler une course ?",
                            answer: "Vous pouvez annuler une course depuis l'écran de suivi en appuyant sur le bouton 'Annuler'. Les frais d'annulation peuvent s'appliquer selon le moment de l'annulation."
                        ),
                        FAQItem(
                            id: "4",
                            question: "Comment contacter un conducteur ?",
                            answer: "Vous pouvez appeler le conducteur directement depuis l'application en appuyant sur le bouton d'appel dans l'écran de suivi de course."
                        ),
                        FAQItem(
                            id: "5",
                            question: "Comment évaluer un conducteur ?",
                            answer: "Après la fin de votre course, vous pouvez évaluer le conducteur en donnant une note de 1 à 5 étoiles et en laissant un commentaire optionnel."
                        )
                    ]
                }
                print("❌ Erreur loadFAQ: \(error)")
            }
        }
    }
    
    func toggleFAQItem(_ itemId: String) {
        if expandedFAQItem == itemId {
            expandedFAQItem = nil
        } else {
            expandedFAQItem = itemId
        }
    }
    
    // MARK: - Support Messages
    
    func sendSupportMessage(_ message: String) async -> Bool {
        guard !message.isEmpty else { return false }
        
        await MainActor.run {
            isSending = true
            errorMessage = nil
        }
        
        do {
            // Envoyer le message au backend
            try await apiService.sendSupportMessage(message: message)
            
            // Créer un message local pour l'affichage immédiat
            let supportMessage = SupportMessage(
                id: UUID().uuidString,
                message: message,
                isFromUser: true,
                timestamp: Date()
            )
            
            await MainActor.run {
                supportMessages.append(supportMessage)
                currentMessage = ""
                isSending = false
            }
            
            // Recharger les messages depuis le backend pour avoir la version complète
            await loadSupportMessages()
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du message: \(error.localizedDescription)"
                isSending = false
            }
            print("❌ Erreur sendSupportMessage: \(error)")
            return false
        }
    }
    
    func loadSupportMessages() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let messages = try await apiService.getSupportMessages()
            
            await MainActor.run {
                supportMessages = messages
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des messages: \(error.localizedDescription)"
                isLoading = false
                supportMessages = []
            }
            print("❌ Erreur loadSupportMessages: \(error)")
        }
    }
    
    // MARK: - Support Tickets
    
    func createSupportTicket(subject: String, message: String, category: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let ticket = try await apiService.createSupportTicket(subject: subject, message: message, category: category)
            
            await MainActor.run {
                supportTickets.append(ticket)
                isLoading = false
                successMessage = "Ticket créé avec succès"
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création du ticket: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur createSupportTicket: \(error)")
            return false
        }
    }
    
    func loadSupportTickets() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let tickets = try await apiService.getSupportTickets()
            
            await MainActor.run {
                supportTickets = tickets
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors du chargement des tickets: \(error.localizedDescription)"
                isLoading = false
                supportTickets = []
            }
            print("❌ Erreur loadSupportTickets: \(error)")
        }
    }
    
    // MARK: - Report Problem
    
    func reportProblem(description: String, category: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.reportProblem(description: description, category: category)
            
            await MainActor.run {
                successMessage = "Votre rapport a été envoyé avec succès"
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du rapport: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur reportProblem: \(error)")
            return false
        }
    }
    
    // MARK: - App Information
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (\(build))"
        }
        return "Version 1.0.0"
    }
    
    // MARK: - Support Information
    
    var supportPhoneNumber: String {
        return "+243 900 000 000"
    }
    
    var supportEmail: String {
        return "support@tshiakanivtc.com"
    }
    
    // MARK: - Carrier Information
    
    var carrierName: String {
        return "Tshiakani VTC"
    }
    
    var carrierPhoneNumber: String {
        return "+243 900 000 000"
    }
    
    var carrierEmail: String {
        return "contact@tshiakani.com"
    }
    
    var carrierAddress: String {
        return "Kinshasa, République Démocratique du Congo"
    }
    
    var carrierHours: String {
        return "24/7"
    }
    
    // MARK: - Legal URLs
    
    var termsOfServiceURL: String {
        return "https://tshiakanivtc.com/terms"
    }
    
    var privacyPolicyURL: String {
        return "https://tshiakanivtc.com/privacy"
    }
    
    // MARK: - Contact Actions
    
    func callSupport(phoneNumber: String) {
        let cleanedPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let phoneURL = URL(string: "tel://\(cleanedPhone)") {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
            }
            #endif
        }
    }
    
    func sendEmail(to email: String) {
        if let emailURL = URL(string: "mailto:\(email)") {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            }
            #endif
        }
    }
    
    func openURL(urlString: String) {
        if let url = URL(string: urlString) {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            #endif
        }
    }
}
