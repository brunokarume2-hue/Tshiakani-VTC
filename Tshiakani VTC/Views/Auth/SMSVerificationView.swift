//
//  SMSVerificationView.swift
//  Tshiakani VTC
//
//  Vue de vérification du code SMS (4 à 6 chiffres)
//

import SwiftUI

struct SMSVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authViewModel = AuthViewModel()
    
    let userName: String?
    let phoneNumber: String
    let role: UserRole
    
    @State private var code: [String] = Array(repeating: "", count: 6) // 6 champs (backend génère des codes à 6 chiffres)
    @FocusState private var focusedField: Int?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var canResend = false
    @State private var resendTimer = 60
    @Environment(\.dismiss) var dismiss
    @State private var authenticationSuccess = false
    
    var fullPhoneNumber: String {
        "+243 \(phoneNumber)"
    }
    
    var isCodeComplete: Bool {
        code.allSatisfy { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.spacingXL) {
                // En-tête avec animation
                VStack(spacing: AppDesign.spacingL) {
                    // Icône SMS avec effet
                    ZStack {
                        // Cercle avec effet de pulsation
                        Circle()
                            .fill(AppColors.accentOrange.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .blur(radius: 15)
                        
                        Circle()
                            .fill(AppColors.accentOrange.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(AppColors.accentOrange)
                            .symbolEffect(.bounce, value: UUID())
                    }
                    .padding(.top, 60)
                    .transition(.scale.combined(with: .opacity))
                    
                    VStack(spacing: AppDesign.spacingS) {
                        Text("Vérification")
                            .font(AppTypography.largeTitle(weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Nous avons envoyé un code à")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(fullPhoneNumber)
                            .font(AppTypography.subheadline(weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, AppDesign.spacingM)
                            .padding(.vertical, AppDesign.spacingS)
                            .background(AppColors.accentOrangeLight)
                            .cornerRadius(AppDesign.cornerRadiusM)
                    }
                    .multilineTextAlignment(.center)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.horizontal, AppDesign.spacingM)
                
                // Champs de code (6 champs - backend génère des codes à 6 chiffres)
                VStack(spacing: AppDesign.spacingL) {
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: $code[index])
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .frame(width: 50, height: 60)
                                .multilineTextAlignment(.center)
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppDesign.cornerRadiusM)
                                .focused($focusedField, equals: index)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                        .stroke(
                                            focusedField == index ? AppColors.accentOrange : AppColors.border.opacity(0.3),
                                            lineWidth: focusedField == index ? 2 : 1
                                        )
                                )
                                .scaleEffect(focusedField == index ? 1.05 : 1.0)
                                .animation(AppDesign.animationSnappy, value: focusedField == index)
                                .onChange(of: code[index]) { _, newValue in
                                    handleCodeInput(at: index, newValue: newValue)
                                }
                        }
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // Bouton vérifier avec gradient orange (inspiré de l'image)
                    Button(action: {
                        HapticFeedback.medium()
                        verifyCode()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Vérifier")
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                AppColors.accentOrange,
                                AppColors.accentOrangeDark
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppDesign.cornerRadiusL)
                    .buttonShadow()
                    .padding(.horizontal, AppDesign.spacingXL)
                    .disabled(!isCodeComplete || isLoading)
                    .opacity(isCodeComplete && !isLoading ? 1.0 : 0.6)
                    
                    // Options de renvoi
                    VStack(spacing: AppDesign.spacingM) {
                        Button(action: {
                            resendCode()
                        }) {
                            Text("Renvoyer le code")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.accentOrange)
                        }
                        .disabled(!canResend)
                        
                        if !canResend {
                            Text("Renvoyer dans \(resendTimer) secondes")
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                    }
                    .padding(.top, AppDesign.spacingS)
                    
                    // Message d'erreur
                    if let error = errorMessage {
                        HStack(spacing: AppDesign.spacingS) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.error)
                            
                            Text(error)
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.error)
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                    }
                }
                .padding(.top, 40)
                
                    Spacer()
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                focusedField = 0
                startResendTimer()
            }
            .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
                if newValue {
                    print("✅ SMSVerificationView: Authentification réussie (changé de \(oldValue) à \(newValue)), fermeture de la vue")
                    // Fermer cette vue pour que RootView puisse rediriger
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleCodeInput(at index: Int, newValue: String) {
        // Limiter à un seul chiffre
        if newValue.count > 1 {
            code[index] = String(newValue.prefix(1))
        }
        
        // Ne garder que les chiffres
        code[index] = code[index].filter { $0.isNumber }
        
        // Passer au champ suivant si un chiffre est entré (6 champs)
        if !code[index].isEmpty && index < 5 {
            focusedField = index + 1
        }
        
        // Vérifier automatiquement si le code est complet
        if isCodeComplete {
            verifyCode()
        }
    }
    
    private func verifyCode() {
        let fullCode = code.joined()
        
        // Validation basique (en production, vérifier avec l'API)
        // Code à 6 chiffres (backend génère des codes à 6 chiffres)
        guard fullCode.count == 6 && fullCode.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Code invalide"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Vérification du code OTP via l'API backend
        Task {
            do {
                // Formater le numéro de téléphone
                let fullPhoneNumber = phoneNumber.hasPrefix("+243") 
                    ? phoneNumber 
                    : "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
                
                // Vérifier le code OTP et se connecter
                await authViewModel.verifyOTP(
                    phoneNumber: fullPhoneNumber,
                    code: fullCode,
                    role: role,
                    userName: userName ?? nil
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    if authViewModel.isAuthenticated {
                        // AuthManager sera mis à jour automatiquement car le token est dans UserDefaults
                        authManager.checkAuthStatus()
                        print("✅ Authentification réussie - isAuthenticated: \(authManager.isAuthenticated), role: \(authManager.userRole?.rawValue ?? "nil")")
                    } else {
                        errorMessage = authViewModel.errorMessage ?? "Code invalide. Veuillez réessayer."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur lors de la vérification: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func resendCode() {
        canResend = false
        resendTimer = 60
        startResendTimer()
        
        // Appeler l'API pour renvoyer le code
        Task {
            let fullPhoneNumber = phoneNumber.hasPrefix("+243") 
                ? phoneNumber 
                : "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
            
            await authViewModel.sendOTP(phoneNumber: fullPhoneNumber, channel: "sms")
            
            await MainActor.run {
                if let error = authViewModel.errorMessage {
                    errorMessage = error
                }
            }
        }
    }
    
    private func startResendTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            resendTimer -= 1
            if resendTimer <= 0 {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SMSVerificationView(
            userName: "Jean Dupont",
            phoneNumber: "820 098 808",
            role: .client
        )
        .environmentObject(AuthManager())
    }
}

