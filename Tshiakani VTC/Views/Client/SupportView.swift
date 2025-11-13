//
//  SupportView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct ClientSupportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supportViewModel = SupportViewModel()
    @State private var showingSuccessAlert = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Votre message") {
                    TextEditor(text: $supportViewModel.currentMessage)
                        .frame(height: 150)
                }
                
                Section {
                    Button(action: sendMessage) {
                        HStack {
                            Spacer()
                            if supportViewModel.isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Envoyer")
                            }
                            Spacer()
                        }
                    }
                    .disabled(supportViewModel.currentMessage.isEmpty || supportViewModel.isSending)
                }
                
                Section("Contact direct") {
                    Button(action: {
                        if let url = URL(string: "tel://+243900000000") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Appeler")
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@tshiakanivtc.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Envoyer un email")
                        }
                    }
                }
            }
            .navigationTitle("Assistance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Message envoyé", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre message a été envoyé. Nous vous répondrons dans les plus brefs délais.")
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(supportViewModel.errorMessage ?? "Une erreur est survenue")
            }
            .onChange(of: supportViewModel.successMessage) { _, message in
                if message != nil {
                    showingSuccessAlert = true
                }
            }
            .onChange(of: supportViewModel.errorMessage) { _, error in
                if error != nil {
                    showingError = true
                }
            }
        }
    }
    
    private func sendMessage() {
        Task {
            let success = await supportViewModel.sendSupportMessage(supportViewModel.currentMessage)
            if success {
                supportViewModel.currentMessage = ""
            }
        }
    }
}

#Preview {
    ClientSupportView()
}

