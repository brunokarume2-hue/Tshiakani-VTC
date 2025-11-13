//
//  ChatView.swift
//  Tshiakani VTC
//
//  Écran de chat avec le conducteur
//

import SwiftUI

struct ChatView: View {
    let driverName: String
    let driverId: String
    let rideId: String?
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var chatViewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    init(driverName: String, driverId: String, rideId: String?) {
        self.driverName = driverName
        self.driverId = driverId
        self.rideId = rideId
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(rideId: rideId, driverId: driverId))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Liste des messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppDesign.spacingM) {
                            if chatViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                                    .padding()
                            } else {
                                ForEach(chatViewModel.messages) { message in
                                    ChatMessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(AppDesign.spacingM)
                    }
                    .onChange(of: chatViewModel.messages.count) { _, _ in
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Barre de saisie
                HStack(spacing: AppDesign.spacingS) {
                    TextField("Tapez un message...", text: $chatViewModel.currentMessage)
                        .font(AppTypography.body())
                        .padding(AppDesign.spacingM)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        if chatViewModel.isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(chatViewModel.currentMessage.isEmpty ? AppColors.secondaryText : AppColors.accentOrange)
                        }
                    }
                    .disabled(chatViewModel.currentMessage.isEmpty || chatViewModel.isSending)
                }
                .padding(AppDesign.spacingM)
                .background(AppColors.background)
            }
            .navigationTitle(driverName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
            .alert("Erreur", isPresented: .constant(chatViewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    chatViewModel.errorMessage = nil
                }
            } message: {
                Text(chatViewModel.errorMessage ?? "Une erreur est survenue")
            }
        }
    }
    
    private func sendMessage() {
        guard !chatViewModel.currentMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        Task {
            let success = await chatViewModel.sendMessage(chatViewModel.currentMessage)
            if success {
                chatViewModel.currentMessage = ""
            }
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        // Déterminer si le message est de l'utilisateur actuel
        // En comparant senderId avec l'ID de l'utilisateur actuel
        return !message.isFromDriver
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.message)
                    .font(AppTypography.body())
                    .foregroundColor(isFromCurrentUser ? .white : AppColors.primaryText)
                    .padding(AppDesign.spacingM)
                    .background(
                        isFromCurrentUser ?
                        AppColors.accentOrange :
                        AppColors.secondaryBackground
                    )
                    .cornerRadius(AppDesign.cornerRadiusM)
                
                Text(message.timestamp, style: .time)
                    .font(AppTypography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    ChatView(driverName: "Dennis Oliver", driverId: "driver123", rideId: "ride123")
}
