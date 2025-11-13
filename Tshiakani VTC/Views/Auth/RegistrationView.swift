//
//  RegistrationView.swift
//  Tshiakani VTC
//
//  Vue d'inscription simplifiée avec mot de passe
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authViewModel = AuthViewModel()
    @State private var phoneNumber = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
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
        NavigationStack {
            ZStack {
                // Fond avec dégradé orange en bas (inspiré de l'image)
                VStack(spacing: 0) {
                    AppColors.background
                    
                    LinearGradient(
                        colors: [
                            AppColors.accentOrange.opacity(0.08),
                            AppColors.accentOrange.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 300)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppDesign.spacingXL) {
                        // Logo et titre (inspiré de l'image)
                        VStack(spacing: AppDesign.spacingL) {
                            ZStack {
                                // Cercle de fond avec effet
                                Circle()
                                    .fill(AppColors.accentOrange.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentOrange.opacity(0.2),
                                                AppColors.accentOrange.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "car.fill")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(AppColors.accentOrange)
                            }
                            .padding(.top, 40)
                            
                            Text("Inscription")
                                .font(AppTypography.largeTitle(weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .padding(.top, AppDesign.spacingL)
                        
                        // Formulaire avec champs arrondis (inspiré de l'image)
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
                            
                            // Champ mot de passe avec indicateur de force
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
                                
                                // Indicateur de force du mot de passe (inspiré de l'image)
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
                        }
                        .padding(.horizontal, AppDesign.spacingXL)
                        
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
                            .padding(.horizontal, AppDesign.spacingXL)
                        }
                        
                        // Message de validation
                        if !password.isEmpty && password.count < 6 {
                            HStack(spacing: AppDesign.spacingS) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.warning)
                                
                                Text("Le mot de passe doit contenir au moins 6 caractères")
                                    .font(AppTypography.caption())
                                    .foregroundColor(AppColors.warning)
                            }
                            .padding(.horizontal, AppDesign.spacingXL)
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
                            .padding(.horizontal, AppDesign.spacingXL)
                        }
                        
                        // Bouton inscription avec gradient orange (inspiré de l'image)
                        Button(action: {
                            HapticFeedback.medium()
                            
                            isLoading = true
                            errorMessage = nil
                            
                            Task {
                                let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
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
                            Group {
                                if isFormValid && !isLoading && !authViewModel.isLoading {
                                    LinearGradient(
                                        colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [AppColors.accentOrange.opacity(0.5), AppColors.accentOrangeDark.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .buttonShadow()
                        .disabled(!isFormValid || isLoading || authViewModel.isLoading)
                        .padding(.horizontal, AppDesign.spacingXL)
                    }
                    .padding(.bottom, AppDesign.spacingXL)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
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

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 10 {
            return .medium
        } else {
            // Vérifier la complexité
            let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
            let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
            let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
            let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
            
            let complexity = [hasUpperCase, hasLowerCase, hasNumbers, hasSpecialChars].filter { $0 }.count
            
            if complexity >= 3 {
                return .strong
            } else if complexity >= 2 {
                return .medium
            } else {
                return .weak
            }
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case .weak:
            return AppColors.error
        case .medium:
            return AppColors.warning
        case .strong:
            return AppColors.success
        }
    }
    
    private var strengthText: String {
        switch strength {
        case .weak:
            return "Faible"
        case .medium:
            return "Moyen"
        case .strong:
            return "Fort"
        }
    }
    
    private var strengthPercentage: CGFloat {
        switch strength {
        case .weak:
            return 0.33
        case .medium:
            return 0.66
        case .strong:
            return 1.0
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingXS) {
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fond
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.border.opacity(0.2))
                        .frame(height: 4)
                    
                    // Barre de force
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strengthColor)
                        .frame(width: geometry.size.width * strengthPercentage, height: 4)
                        .animation(AppDesign.animationFast, value: strengthPercentage)
                }
            }
            .frame(height: 4)
            
            // Texte de force
            HStack {
                Text("Force du mot de passe:")
                    .font(AppTypography.caption())
                    .foregroundColor(AppColors.secondaryText)
                
                Text(strengthText)
                    .font(AppTypography.caption(weight: .semibold))
                    .foregroundColor(strengthColor)
            }
        }
        .padding(.top, AppDesign.spacingXS)
    }
}

enum PasswordStrength {
    case weak
    case medium
    case strong
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RegistrationView()
            .environmentObject(AuthManager())
    }
}
