//
//  ChangePasswordView.swift
//  Tshiakani VTC
//
//  Vue pour changer le mot de passe (utilisateur connecté)
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authViewModel = AuthViewModel()
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case current, password, confirmPassword
    }
    
    var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppDesign.spacingXL) {
                        // Logo et titre
                        VStack(spacing: AppDesign.spacingL) {
                            Circle()
                                .fill(AppColors.accentOrange.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "lock.rotation")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundColor(AppColors.accentOrange)
                                )
                            
                            Text("Changer le mot de passe")
                                .font(AppTypography.largeTitle(weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Entrez votre mot de passe actuel et votre nouveau mot de passe")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppDesign.spacingL)
                        }
                        .padding(.top, AppDesign.spacingXL)
                        
                        // Formulaire
                        VStack(spacing: AppDesign.spacingM) {
                            // Champ mot de passe actuel
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Mot de passe actuel")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                SecureField("Votre mot de passe actuel", text: $currentPassword)
                                    .font(AppTypography.body())
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .current)
                                    .padding(.horizontal, AppDesign.spacingM)
                                    .padding(.vertical, AppDesign.spacingM)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppDesign.cornerRadiusM)
                            }
                            
                            // Champ nouveau mot de passe
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Nouveau mot de passe")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                SecureField("Votre nouveau mot de passe", text: $newPassword)
                                    .font(AppTypography.body())
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                                    .padding(.horizontal, AppDesign.spacingM)
                                    .padding(.vertical, AppDesign.spacingM)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppDesign.cornerRadiusM)
                                
                                if !newPassword.isEmpty && newPassword.count < 6 {
                                    Text("Le mot de passe doit contenir au moins 6 caractères")
                                        .font(AppTypography.caption())
                                        .foregroundColor(AppColors.error)
                                }
                            }
                            
                            // Champ confirmation
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Confirmer le mot de passe")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                SecureField("Confirmez votre nouveau mot de passe", text: $confirmPassword)
                                    .font(AppTypography.body())
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .padding(.horizontal, AppDesign.spacingM)
                                    .padding(.vertical, AppDesign.spacingM)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppDesign.cornerRadiusM)
                                
                                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                    Text("Les mots de passe ne correspondent pas")
                                        .font(AppTypography.caption())
                                        .foregroundColor(AppColors.error)
                                }
                            }
                        }
                        .padding(.horizontal, AppDesign.spacingL)
                        
                        // Message d'erreur
                        if let error = errorMessage ?? authViewModel.errorMessage {
                            Text(error)
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, AppDesign.spacingL)
                        }
                        
                        // Bouton changer
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            isLoading = true
                            errorMessage = nil
                            
                            Task {
                                await authViewModel.changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword
                                )
                                
                                await MainActor.run {
                                    isLoading = false
                                    if authViewModel.errorMessage == nil {
                                        showSuccess = true
                                        // Réinitialiser les champs
                                        currentPassword = ""
                                        newPassword = ""
                                        confirmPassword = ""
                                    } else {
                                        errorMessage = authViewModel.errorMessage ?? "Erreur lors du changement de mot de passe"
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isLoading || authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Changer le mot de passe")
                                        .font(AppTypography.headline(weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .background(isFormValid && !isLoading && !authViewModel.isLoading ? AppColors.accentOrange : AppColors.accentOrange.opacity(0.5))
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .buttonShadow()
                        .disabled(!isFormValid || isLoading || authViewModel.isLoading)
                        .padding(.horizontal, AppDesign.spacingL)
                    }
                    .padding(.bottom, AppDesign.spacingXL)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Mot de passe modifié", isPresented: $showSuccess) {
                Button("OK") {
                    // Fermer la vue
                }
            } message: {
                Text("Votre mot de passe a été modifié avec succès.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthManager())
    }
}

