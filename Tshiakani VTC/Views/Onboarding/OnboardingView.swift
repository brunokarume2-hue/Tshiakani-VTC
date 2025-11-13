//
//  OnboardingView.swift
//  Tshiakani VTC
//
//  Vue d'onboarding avec carrousel inspiré du design moderne
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentPage = 0
    @State private var navigateToAuth = false
    
    // Pages d'onboarding inspirées de l'image (4 pages)
    private let onboardingPages = [
        OnboardingPage(
            title: "Choisissez votre itinéraire",
            subtitle: "Facilement",
            description: "Sélectionnez votre point de départ et votre destination en quelques secondes",
            icon: "map.fill",
            illustrationColor: AppColors.accentOrange
        ),
        OnboardingPage(
            title: "Demandez une course",
            subtitle: "Rapidement",
            description: "Commandez un véhicule en quelques secondes et arrivez à destination en toute sécurité",
            icon: "car.fill",
            illustrationColor: AppColors.accentOrange
        ),
        OnboardingPage(
            title: "Obtenez votre taxi",
            subtitle: "Simplement",
            description: "Suivez votre chauffeur en temps réel et arrivez à destination rapidement",
            icon: "location.fill",
            illustrationColor: AppColors.accentOrange
        ),
        OnboardingPage(
            title: "Gagnez du temps",
            subtitle: "Avec nous",
            description: "Transport rapide et sécurisé pour tous vos déplacements à Kinshasa",
            icon: "clock.fill",
            illustrationColor: AppColors.accentOrange
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // OPTIMISATION: Fond simple sans gradient pour améliorer les performances
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Contenu principal avec TabView
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(page: onboardingPages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .onChange(of: currentPage) { _, _ in
                        HapticFeedback.selection()
                    }
                    
                    // Boutons de navigation en bas
                    VStack(spacing: AppDesign.spacingM) {
                        // Bouton principal
                        Button(action: {
                            HapticFeedback.medium()
                            
                            if currentPage < onboardingPages.count - 1 {
                                withAnimation(AppDesign.animationSmooth) {
                                    currentPage += 1
                                }
                            } else {
                                // Dernière page - aller à l'authentification
                                authManager.completeOnboarding()
                                navigateToAuth = true
                            }
                        }) {
                            HStack {
                                Text(currentPage < onboardingPages.count - 1 ? "Suivant" : "Commencer")
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if currentPage < onboardingPages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .background(
                            LinearGradient(
                                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .buttonShadow()
                        .padding(.horizontal, AppDesign.spacingXL)
                        
                        // Bouton Skip (visible seulement si pas sur la dernière page)
                        if currentPage < onboardingPages.count - 1 {
                            Button(action: {
                                HapticFeedback.light()
                                authManager.completeOnboarding()
                                navigateToAuth = true
                            }) {
                                Text("Passer")
                                    .font(AppTypography.body(weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(.bottom, AppDesign.spacingL)
                        }
                    }
                    .padding(.bottom, 50)
                    .background(
                        LinearGradient(
                            colors: [
                                AppColors.background.opacity(0),
                                AppColors.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 150)
                        .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthGateView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppDesign.spacingXL) {
            Spacer()
            
            // Grande illustration centrée (inspirée de l'image)
            ZStack {
                // Cercle de fond avec effet de profondeur
                Circle()
                    .fill(page.illustrationColor.opacity(0.15))
                    .frame(width: 220, height: 220)
                    .blur(radius: 30)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                page.illustrationColor.opacity(0.2),
                                page.illustrationColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Icône principale
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(page.illustrationColor)
            }
            .padding(.top, 60)
            
            // Titre et sous-titre (inspirés de l'image)
            VStack(spacing: AppDesign.spacingS) {
                Text(page.title)
                    .font(AppTypography.largeTitle(weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(AppTypography.largeTitle(weight: .bold))
                    .foregroundColor(AppColors.accentOrange)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(AppTypography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppDesign.spacingXL)
                    .padding(.top, AppDesign.spacingS)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppDesign.spacingL)
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let illustrationColor: Color
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}
