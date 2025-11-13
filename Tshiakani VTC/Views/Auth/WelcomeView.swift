//
//  WelcomeView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import UIKit

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedRole: UserRole = .client
    @State private var phoneNumber = ""
    @State private var userName = ""
    @State private var showingMainView = false
    @State private var showingSMSVerification = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond adaptatif selon le mode sombre
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // En-tête avec logo moderne
                        VStack(spacing: AppDesign.spacingL) {
                            // Logo dans un conteneur élégant
                            ZStack {
                                // Fond avec gradient subtil
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusXL)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentOrange,
                                                AppColors.accentOrange.opacity(0.85)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 180)
                                    .padding(.horizontal, AppDesign.spacingM)
                                    .padding(.top, AppDesign.spacingXL)
                                    .cardShadow()
                                
                                // Icône de voiture moderne
                                VStack(spacing: AppDesign.spacingM) {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 64, weight: .medium))
                                        .foregroundColor(.white)
                                        .symbolEffect(.bounce, value: selectedRole)
                                    
                                    Text("Tshiakani VTC")
                                        .font(AppTypography.title1(weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Titre et tagline avec typographie Apple
                            VStack(spacing: AppDesign.spacingS) {
                                Text("Bienvenue")
                                    .font(AppTypography.largeTitle(weight: .bold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Transport rapide et sécurisé")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(.top, AppDesign.spacingM)
                        }
                        .padding(.bottom, AppDesign.spacingXL)
                        
                        // Formulaire avec design moderne
                        VStack(spacing: AppDesign.spacingL) {
                            // Sélection du rôle avec design amélioré
                            VStack(alignment: .leading, spacing: AppDesign.spacingM) {
                                Text("Je suis un...")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(.horizontal, AppDesign.spacingM)
                                
                                HStack(spacing: AppDesign.spacingM) {
                                    RoleButton(
                                        title: "Client",
                                        icon: "person.fill",
                                        isSelected: selectedRole == .client
                                    ) {
                                        withAnimation(AppDesign.animationStandard) {
                                            selectedRole = .client
                                        }
                                    }
                                }
                                .padding(.horizontal, AppDesign.spacingM)
                            }
                            
                            // Champ nom (optionnel) avec design amélioré
                            TshiakaniTextField(
                                title: "Nom (Optionnel)",
                                placeholder: "Votre nom",
                                text: $userName,
                                icon: "person.fill"
                            )
                            .padding(.horizontal, AppDesign.spacingM)
                            
                            // Champ téléphone avec design amélioré
                            VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                                Text("Numéro de téléphone")
                                    .font(AppTypography.subheadline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: AppDesign.spacingS) {
                                    // Indicateur de pays
                                    HStack(spacing: 4) {
                                        Text("🇨🇩")
                                            .font(.title3)
                                        Text("+243")
                                            .font(AppTypography.body(weight: .medium))
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    .padding(.horizontal, AppDesign.spacingM)
                                    .padding(.vertical, AppDesign.spacingM)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppDesign.cornerRadiusM)
                                    
                                    TextField("820 098 808", text: $phoneNumber)
                                        .font(AppTypography.body())
                                        .keyboardType(.phonePad)
                                        .textContentType(.telephoneNumber)
                                }
                                .padding(AppDesign.spacingM)
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppDesign.cornerRadiusM)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, AppDesign.spacingM)
                            
                            // Bouton de connexion rapide avec compte de test
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Remplir automatiquement les champs avec le compte de test
                                phoneNumber = FeatureFlags.testAccountPhoneNumber.replacingOccurrences(of: "+243", with: "")
                                userName = FeatureFlags.testAccountName
                                selectedRole = FeatureFlags.testAccountRole
                                
                                // Se connecter automatiquement
                                Task {
                                    await authViewModel.signIn(
                                        phoneNumber: FeatureFlags.testAccountPhoneNumber,
                                        role: FeatureFlags.testAccountRole,
                                        userName: FeatureFlags.testAccountName
                                    )
                                    if authViewModel.isAuthenticated {
                                        showingMainView = true
                                    }
                                }
                            }) {
                                HStack(spacing: AppDesign.spacingS) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Connexion rapide (Compte Test)")
                                        .font(AppTypography.subheadline(weight: .medium))
                                }
                                .foregroundColor(AppColors.accentOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                                    .fill(AppColors.accentOrangeLight.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                                            .stroke(AppColors.accentOrange, lineWidth: 1.5)
                                    )
                            )
                            .padding(.horizontal, AppDesign.spacingM)
                            .disabled(authViewModel.isLoading)
                            
                            // Bouton continuer avec design moderne
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                Task {
                                    // Ajouter le préfixe +243 si nécessaire
                                    let fullPhoneNumber = phoneNumber.hasPrefix("+243") 
                                        ? phoneNumber 
                                        : "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
                                    
                                    // Envoyer le code OTP d'abord via SMS (Twilio)
                                    await authViewModel.sendOTP(phoneNumber: fullPhoneNumber, channel: "sms")
                                    
                                    // Si l'envoi réussit, naviguer vers l'écran de vérification
                                    if !authViewModel.isLoading && authViewModel.errorMessage == nil {
                                        showingSMSVerification = true
                                    }
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Continuer")
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
                                        AppColors.accentOrange.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(AppDesign.cornerRadiusL)
                            .buttonShadow()
                            .padding(.horizontal, AppDesign.spacingM)
                            .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
                            .primaryButtonStyle()
                            
                            // Message d'erreur avec design amélioré
                            if let error = authViewModel.errorMessage {
                                HStack(spacing: AppDesign.spacingS) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(AppTypography.caption())
                                        .foregroundColor(AppColors.error)
                                    
                                    Text(error)
                                        .font(AppTypography.caption())
                                        .foregroundColor(AppColors.error)
                                }
                                .padding(.horizontal, AppDesign.spacingM)
                                .padding(.top, AppDesign.spacingS)
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $showingSMSVerification) {
                SMSVerificationView(
                    userName: userName.isEmpty ? nil : userName,
                    phoneNumber: phoneNumber,
                    role: selectedRole
                )
                .environmentObject(AuthManager())
            }
            .navigationDestination(isPresented: $showingMainView) {
                if authViewModel.currentUser?.role == .client {
                    ClientMainView()
                        .environmentObject(authViewModel)
                } else {
                    AdminDashboardView()
                }
            }
        }
    }
}

struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback léger
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            action()
        }) {
            VStack(spacing: AppDesign.spacingM) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(title)
                    .font(AppTypography.headline())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppDesign.spacingL)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                            .fill(AppColors.accentOrangeLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentOrange,
                                                AppColors.accentOrange.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                            .fill(AppColors.secondaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                }
            )
            .foregroundColor(
                isSelected ? AppColors.accentOrange : AppColors.secondaryText
            )
        }
        .secondaryButtonStyle()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
