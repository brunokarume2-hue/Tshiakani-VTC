//
//  AuthGateView.swift
//  Tshiakani VTC
//
//  Vue d'authentification unifiée avec onglets Connexion/Inscription - Simplifiée pour performance
//

import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: AuthTab = .login
    @StateObject private var authViewModel = AuthViewModel()
    @State private var navigateToForgotPassword = false
    
    enum AuthTab: String, CaseIterable {
        case login = "Connexion"
        case registration = "Inscription"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // OPTIMISATION: Fond simple sans gradient pour performance
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppDesign.spacingXL) {
                        // Logo simplifié (sans animations ni effets pour performance)
                        VStack(spacing: AppDesign.spacingM) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(AppColors.accentOrange)
                                .padding(.top, 40)
                            
                            Text("Tshiakani VTC")
                                .font(AppTypography.largeTitle(weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Transport rapide et sécurisé")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppDesign.spacingL)
                        
                        // Sélecteur d'onglets
                        Picker("Mode", selection: $selectedTab) {
                            ForEach(AuthTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, AppDesign.spacingXL)
                        .padding(.top, AppDesign.spacingM)
                        
                        // Formulaire selon l'onglet sélectionné
                        Group {
                            if selectedTab == .login {
                                LoginFormView(
                                    authViewModel: authViewModel,
                                    onNavigateToForgotPassword: {
                                        navigateToForgotPassword = true
                                    }
                                )
                                .environmentObject(authManager)
                            } else {
                                RegistrationFormView(authViewModel: authViewModel)
                                    .environmentObject(authManager)
                            }
                        }
                        .padding(.top, AppDesign.spacingL)
                    }
                    .padding(.bottom, AppDesign.spacingXL)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Login Form

struct LoginFormView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var authViewModel: AuthViewModel
    let onNavigateToForgotPassword: () -> Void
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case phone, password
    }
    
    var isFormValid: Bool {
        !phoneNumber.isEmpty && phoneNumber.count >= 9 && !password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: AppDesign.spacingM) {
            // Champ téléphone
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Numéro de téléphone")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                HStack(spacing: AppDesign.spacingS) {
                    Text("+243")
                        .font(AppTypography.body(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.vertical, AppDesign.spacingM)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppDesign.cornerRadiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                .stroke(focusedField == .phone ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .phone ? 2 : 1)
                        )
                    
                    TextField("820 098 808", text: $phoneNumber)
                        .font(AppTypography.body())
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                        .onChange(of: phoneNumber) { _, newValue in
                            phoneNumber = formatPhoneNumber(newValue)
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.vertical, AppDesign.spacingM)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppDesign.cornerRadiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                .stroke(focusedField == .phone ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .phone ? 2 : 1)
                        )
                }
            }
            
            // Champ mot de passe
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Mot de passe")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                SecureField("Votre mot de passe", text: $password)
                    .font(AppTypography.body())
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingM)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                            .stroke(focusedField == .password ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .password ? 2 : 1)
                    )
            }
            
            // Message d'erreur
            if let error = errorMessage ?? authViewModel.errorMessage {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.error)
                    
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Bouton connexion
            Button(action: {
                HapticFeedback.medium()
                isLoading = true
                errorMessage = nil
                
                Task {
                    let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
                    
                    // Pour le MVP, connexion directe (sans OTP pour simplifier)
                    await authViewModel.login(
                        phoneNumber: fullPhoneNumber,
                        password: password
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        if authViewModel.isAuthenticated {
                            authManager.checkAuthStatus()
                        } else {
                            errorMessage = authViewModel.errorMessage ?? "Erreur lors de la connexion"
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading || authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Se connecter")
                            .font(AppTypography.headline(weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .background(
                isFormValid && !isLoading && !authViewModel.isLoading
                    ? AppColors.accentOrange
                    : AppColors.accentOrange.opacity(0.5)
            )
            .cornerRadius(AppDesign.cornerRadiusL)
            .disabled(!isFormValid || isLoading || authViewModel.isLoading)
            
            // Lien "Mot de passe oublié ?"
            Button(action: {
                onNavigateToForgotPassword()
            }) {
                Text("Mot de passe oublié ?")
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.accentOrange)
            }
            .padding(.top, AppDesign.spacingS)
        }
        .padding(.horizontal, AppDesign.spacingXL)
    }
    
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

// MARK: - Registration Form

struct RegistrationFormView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var authViewModel: AuthViewModel
    @State private var phoneNumber = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: RegistrationField?
    
    enum RegistrationField {
        case phone, name, password, confirmPassword
    }
    
    var isFormValid: Bool {
        !phoneNumber.isEmpty &&
        phoneNumber.count >= 9 &&
        !name.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    var body: some View {
        VStack(spacing: AppDesign.spacingM) {
            // Champ téléphone
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Numéro de téléphone")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                HStack(spacing: AppDesign.spacingS) {
                    Text("+243")
                        .font(AppTypography.body(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.vertical, AppDesign.spacingM)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppDesign.cornerRadiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                .stroke(focusedField == .phone ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .phone ? 2 : 1)
                        )
                    
                    TextField("820 098 808", text: $phoneNumber)
                        .font(AppTypography.body())
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                        .onChange(of: phoneNumber) { _, newValue in
                            phoneNumber = formatPhoneNumber(newValue)
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                        .padding(.vertical, AppDesign.spacingM)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppDesign.cornerRadiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                .stroke(focusedField == .phone ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .phone ? 2 : 1)
                        )
                }
            }
            
            // Champ nom
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Nom complet")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                TextField("Votre nom", text: $name)
                    .font(AppTypography.body())
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingM)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                            .stroke(focusedField == .name ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .name ? 2 : 1)
                    )
            }
            
            // Champ mot de passe
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Mot de passe")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                SecureField("Minimum 6 caractères", text: $password)
                    .font(AppTypography.body())
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingM)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                            .stroke(focusedField == .password ? AppColors.accentOrange : AppColors.border.opacity(0.3), lineWidth: focusedField == .password ? 2 : 1)
                    )
                
                if !password.isEmpty {
                    PasswordStrengthIndicator(password: password)
                }
            }
            
            // Champ confirmation mot de passe
            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                Text("Confirmer le mot de passe")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                SecureField("Répétez le mot de passe", text: $confirmPassword)
                    .font(AppTypography.body())
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingM)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                            .stroke(
                                focusedField == .confirmPassword
                                    ? (password == confirmPassword && !confirmPassword.isEmpty ? AppColors.success : AppColors.error)
                                    : AppColors.border.opacity(0.3),
                                lineWidth: focusedField == .confirmPassword ? 2 : 1
                            )
                    )
            }
            
            // Messages d'erreur
            if let error = errorMessage ?? authViewModel.errorMessage {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.error)
                    
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.error)
                }
            }
            
            if !password.isEmpty && password.count < 6 {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.warning)
                    
                    Text("Le mot de passe doit contenir au moins 6 caractères")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.warning)
                }
            }
            
            if !confirmPassword.isEmpty && password != confirmPassword {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.error)
                    
                    Text("Les mots de passe ne correspondent pas")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Bouton inscription
            Button(action: {
                HapticFeedback.medium()
                isLoading = true
                errorMessage = nil
                
                Task {
                    let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
                    
                    // OPTIMISATION: Inscription directe avec mot de passe (pas d'OTP pour simplifier)
                    await authViewModel.register(
                        phoneNumber: fullPhoneNumber,
                        name: name,
                        password: password,
                        role: .client
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        if authViewModel.isAuthenticated {
                            authManager.checkAuthStatus()
                        } else {
                            errorMessage = authViewModel.errorMessage ?? "Erreur lors de l'inscription"
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading || authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("S'inscrire")
                            .font(AppTypography.headline(weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .background(
                isFormValid && !isLoading && !authViewModel.isLoading
                    ? AppColors.accentOrange
                    : AppColors.accentOrange.opacity(0.5)
            )
            .cornerRadius(AppDesign.cornerRadiusL)
            .disabled(!isFormValid || isLoading || authViewModel.isLoading)
        }
        .padding(.horizontal, AppDesign.spacingXL)
    }
    
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

// MARK: - Password Strength Indicator
// Note: PasswordStrengthIndicator et PasswordStrength sont définis dans RegistrationView.swift

#Preview {
    NavigationStack {
        AuthGateView()
            .environmentObject(AuthManager())
    }
}
