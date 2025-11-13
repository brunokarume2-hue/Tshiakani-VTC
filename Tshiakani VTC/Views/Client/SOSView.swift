//
//  SOSView.swift
//  Tshiakani VTC
//
//  Écran SOS/Emergency
//

import SwiftUI

struct SOSView: View {
    let rideId: String?
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var sosViewModel = SOSViewModel()
    @State private var showConfirmation = false
    @State private var emergencyMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppDesign.spacingXL) {
                Spacer()
                
                // Icône SOS
                ZStack {
                    Circle()
                        .fill(AppColors.error.opacity(0.1))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(AppColors.error)
                }
                .padding(.bottom, AppDesign.spacingL)
                
                // Titre
                VStack(spacing: AppDesign.spacingS) {
                    Text(sosViewModel.isSOSActive ? "Alerte SOS activée" : "Signalement d'urgence")
                        .font(AppTypography.largeTitle(weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(sosViewModel.isSOSActive ? "L'alerte SOS est actuellement active. Vous pouvez la désactiver ci-dessous." : "En cas d'urgence, appuyez sur le bouton ci-dessous pour signaler votre situation.")
                        .font(AppTypography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppDesign.spacingXL)
                }
                
                // Contacts d'urgence
                if !sosViewModel.emergencyContacts.isEmpty {
                    VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                        Text("Contacts d'urgence")
                            .font(AppTypography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        ForEach(sosViewModel.emergencyContacts) { contact in
                            Button(action: {
                                sosViewModel.callEmergencyContact(contact)
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.red)
                                    Text(contact.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(contact.phoneNumber)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppDesign.cornerRadiusM)
                            }
                        }
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                }
                
                Spacer()
                
                // Bouton SOS
                Button(action: {
                    if sosViewModel.isSOSActive {
                        Task {
                            await sosViewModel.deactivateSOS()
                            if sosViewModel.successMessage != nil {
                                showConfirmation = true
                            }
                        }
                    } else {
                        Task {
                            await sosViewModel.activateSOS()
                            if sosViewModel.successMessage != nil {
                                showConfirmation = true
                            }
                        }
                    }
                }) {
                    HStack {
                        if sosViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: sosViewModel.isSOSActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(sosViewModel.isSOSActive ? "Désactiver l'alerte SOS" : "Signaler une urgence")
                                .font(AppTypography.headline(weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .background(sosViewModel.isSOSActive ? AppColors.success : AppColors.error)
                .cornerRadius(AppDesign.cornerRadiusL)
                .buttonShadow()
                .padding(.horizontal, AppDesign.spacingM)
                .disabled(sosViewModel.isLoading)
                
                // Bouton Appeler les secours
                if let firstContact = sosViewModel.emergencyContacts.first {
                    Button(action: {
                        sosViewModel.callEmergencyContact(firstContact)
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Appeler les secours (\(firstContact.phoneNumber))")
                        }
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.error)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppDesign.cornerRadiusL)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.bottom, AppDesign.spacingL)
                }
            }
            .background(AppColors.background)
            .navigationTitle("SOS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
            .alert("Urgence signalée", isPresented: $showConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(sosViewModel.successMessage ?? "Votre signalement d'urgence a été envoyé. Les secours ont été notifiés.")
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(sosViewModel.errorMessage ?? "Une erreur est survenue")
            }
            .onAppear {
                sosViewModel.loadEmergencyContacts()
            }
            .onChange(of: sosViewModel.errorMessage) { _, error in
                if error != nil {
                    showingError = true
                }
            }
            .onChange(of: sosViewModel.successMessage) { _, message in
                if message != nil {
                    showConfirmation = true
                }
            }
        }
    }
}

#Preview {
    SOSView(rideId: "ride123")
}

