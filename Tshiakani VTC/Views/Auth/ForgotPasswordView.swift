//
//  ForgotPasswordView.swift
//  Tshiakani VTC
//
//  Vue pour demander la réinitialisation de mot de passe
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authViewModel = AuthViewModel()
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResetView = false
    @FocusState private var focusedField: Bool
    
    var isFormValid: Bool {
        !phoneNumber.isEmpty && phoneNumber.count >= 9
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
                            
                            Text("Mot de passe oublié ?")
                                .font(AppTypography.largeTitle(weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Entrez votre numéro de téléphone et nous vous enverrons un code de réinitialisation")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppDesign.spacingL)
                        }
                        .padding(.top, AppDesign.spacingXL)
                        
                        // Formulaire
                        VStack(spacing: AppDesign.spacingM) {
                            // Champ téléphone
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Numéro de téléphone")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: AppDesign.spacingS) {
                                    Text("+243")
                                        .font(AppTypography.body(weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(.horizontal, AppDesign.spacingM)
                                        .padding(.vertical, AppDesign.spacingM)
                                        .background(AppColors.secondaryBackground)
                                        .cornerRadius(AppDesign.cornerRadiusM)
                                    
                                    TextField("820 098 808", text: $phoneNumber)
                                        .font(AppTypography.body())
                                        .keyboardType(.phonePad)
                                        .textContentType(.telephoneNumber)
                                        .focused($focusedField)
                                        .onChange(of: phoneNumber) { _, newValue in
                                            phoneNumber = formatPhoneNumber(newValue)
                                        }
                                        .padding(.horizontal, AppDesign.spacingM)
                                        .padding(.vertical, AppDesign.spacingM)
                                        .background(AppColors.secondaryBackground)
                                        .cornerRadius(AppDesign.cornerRadiusM)
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
                        
                        // Bouton envoyer
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            isLoading = true
                            errorMessage = nil
                            
                            Task {
                                let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
                                await authViewModel.forgotPassword(phoneNumber: fullPhoneNumber)
                                
                                await MainActor.run {
                                    isLoading = false
                                    if authViewModel.errorMessage == nil {
                                        showResetView = true
                                    } else {
                                        errorMessage = authViewModel.errorMessage ?? "Erreur lors de l'envoi du code"
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isLoading || authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Envoyer le code")
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
            .navigationDestination(isPresented: $showResetView) {
                ResetPasswordView(phoneNumber: phoneNumber)
                    .environmentObject(authManager)
            }
        }
    }
    
    // MARK: - Fonctions
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        let digits = cleaned.prefix(9).filter { $0.isNumber }
        
        var formatted = ""
        for (index, char) in digits.enumerated() {
            if index > 0 && index % 3 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        return formatted
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthManager())
    }
}

