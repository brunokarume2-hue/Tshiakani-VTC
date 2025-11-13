//
//  ResetPasswordView.swift
//  Tshiakani VTC
//
//  Vue pour réinitialiser le mot de passe avec code OTP
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authViewModel = AuthViewModel()
    let phoneNumber: String
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case code, password, confirmPassword
    }
    
    var isFormValid: Bool {
        !code.isEmpty &&
        code.count == 6 &&
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
                                    Image(systemName: "key.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundColor(AppColors.accentOrange)
                                )
                            
                            Text("Réinitialiser le mot de passe")
                                .font(AppTypography.largeTitle(weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Entrez le code reçu et votre nouveau mot de passe")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppDesign.spacingL)
                        }
                        .padding(.top, AppDesign.spacingXL)
                        
                        // Formulaire
                        VStack(spacing: AppDesign.spacingM) {
                            // Champ code
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Code de vérification")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("123456", text: $code)
                                    .font(AppTypography.body())
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .focused($focusedField, equals: .code)
                                    .onChange(of: code) { _, newValue in
                                        code = String(newValue.prefix(6).filter { $0.isNumber })
                                    }
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
                            }
                            
                            // Champ confirmation
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Confirmer le mot de passe")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                SecureField("Confirmez votre mot de passe", text: $confirmPassword)
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
                        
                        // Bouton réinitialiser
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            isLoading = true
                            errorMessage = nil
                            
                            Task {
                                await authViewModel.resetPassword(
                                    phoneNumber: phoneNumber,
                                    code: code,
                                    newPassword: newPassword
                                )
                                
                                await MainActor.run {
                                    isLoading = false
                                    if authViewModel.errorMessage == nil {
                                        showSuccess = true
                                    } else {
                                        errorMessage = authViewModel.errorMessage ?? "Erreur lors de la réinitialisation"
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isLoading || authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Réinitialiser")
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
            .alert("Mot de passe réinitialisé", isPresented: $showSuccess) {
                Button("OK") {
                    // Retourner à la connexion
                    authManager.checkAuthStatus()
                }
            } message: {
                Text("Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(phoneNumber: "+243820098808")
            .environmentObject(AuthManager())
    }
}

