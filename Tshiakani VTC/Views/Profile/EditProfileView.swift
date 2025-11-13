//
//  EditProfileView.swift
//  Tshiakani VTC
//
//  Écran d'édition du profil utilisateur (simplifié)
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom", text: $name)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveProfile()
                    }
                    .disabled(isLoading || name.isEmpty)
                }
            }
        }
        .onAppear {
            name = authViewModel.currentUser?.name ?? ""
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty else {
            errorMessage = "Veuillez remplir le nom."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authViewModel.updateProfile(name: name)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}

