//
//  AboutView.swift
//  Tshiakani VTC
//
//  Écran d'informations sur l'application
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AboutView: View {
    @StateObject private var supportViewModel = SupportViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo/Icone
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accentOrange)
                    
                    Text("Tshiakani VTC")
                        .font(AppTypography.largeTitle(weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    // Version
                    Text(supportViewModel.appVersion)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.top, 32)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("À propos")
                        .font(AppTypography.title3(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Tshiakani VTC est votre application de transport de confiance en République Démocratique du Congo. Commandez facilement un véhicule et voyagez en toute sécurité.")
                        .font(AppTypography.body())
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                // Contact
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact")
                        .font(AppTypography.title3(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    VStack(spacing: 12) {
                        ContactRow(
                            icon: "phone.fill",
                            title: "Téléphone",
                            value: supportViewModel.supportPhoneNumber,
                            action: {
                                supportViewModel.callSupport(phoneNumber: supportViewModel.supportPhoneNumber)
                            }
                        )
                        
                        ContactRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: supportViewModel.supportEmail,
                            action: {
                                supportViewModel.sendEmail(to: supportViewModel.supportEmail)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                // Liens légaux
                VStack(alignment: .leading, spacing: 16) {
                    Text("Informations légales")
                        .font(AppTypography.title3(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    VStack(spacing: 12) {
                        NavigationLink {
                            TermsOfServiceView()
                        } label: {
                            LegalRow(
                                icon: "doc.text.fill",
                                title: "Conditions d'utilisation"
                            )
                        }
                        .onTapGesture {
                            supportViewModel.openURL(urlString: supportViewModel.termsOfServiceURL)
                        }
                        
                        // Politique de confidentialité
                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            LegalRow(
                                icon: "lock.shield.fill",
                                title: "Politique de confidentialité"
                            )
                        }
                        .onTapGesture {
                            supportViewModel.openURL(urlString: supportViewModel.privacyPolicyURL)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background)
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.accentOrange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.accentOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.caption(weight: .semibold))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(value)
                        .font(AppTypography.body(weight: .medium))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText.opacity(0.5))
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legal Row

struct LegalRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.secondaryText.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Text(title)
                .font(AppTypography.body(weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("About View") {
    NavigationStack {
        AboutView()
    }
}

