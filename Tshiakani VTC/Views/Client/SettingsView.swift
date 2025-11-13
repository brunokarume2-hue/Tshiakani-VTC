//
//  SettingsView.swift
//  Tshiakani VTC
//
//  Écran de paramètres simplifié
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    
    @StateObject private var settingsViewModel = SettingsViewModel(authViewModel: AuthViewModel())
    @State private var showingSignOutConfirmation = false
    @State private var showingNotificationAlert = false
    @State private var notificationAlertMessage = ""
    @State private var showingError = false
    
    var body: some View {
        List {
            // Section Compte
            Section("Compte") {
                NavigationLink {
                    ProfileScreen()
                        .environmentObject(authViewModel)
                        .environmentObject(authManager)
                } label: {
                    SettingsOptionRow(
                        icon: "person.circle.fill",
                        title: "Profil",
                        subtitle: authViewModel.currentUser?.name ?? "Utilisateur",
                        color: AppColors.accentOrange
                    )
                }
                
                NavigationLink {
                    RideHistoryView()
                        .environmentObject(authViewModel)
                } label: {
                    SettingsOptionRow(
                        icon: "clock.fill",
                        title: "Historique",
                        subtitle: "Voir mes courses",
                        color: AppColors.info
                    )
                }
            }
            
            // Section Préférences
            Section("Préférences") {
                Picker("Langue", selection: $settingsViewModel.selectedLanguage) {
                    ForEach(settingsViewModel.availableLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .onChange(of: settingsViewModel.selectedLanguage) { _, newLanguage in
                    settingsViewModel.setLanguage(newLanguage)
                    HapticFeedback.selection()
                }
                
                Picker("Ville", selection: $settingsViewModel.selectedCity) {
                    ForEach(settingsViewModel.availableCities, id: \.self) { city in
                        Text(city).tag(city)
                    }
                }
                .onChange(of: settingsViewModel.selectedCity) { _, newCity in
                    settingsViewModel.setCity(newCity)
                    HapticFeedback.selection()
                }
                
                Toggle("Notifications", isOn: Binding(
                    get: { settingsViewModel.notificationsEnabled },
                    set: { newValue in
                        Task {
                            await settingsViewModel.setNotificationsEnabled(newValue)
                            if let error = settingsViewModel.errorMessage {
                                await MainActor.run {
                                    notificationAlertMessage = error
                                    showingNotificationAlert = true
                                }
                            }
                        }
                    }
                ))
                
                NavigationLink {
                    SecurityView()
                        .environmentObject(authViewModel)
                } label: {
                    SettingsOptionRow(
                        icon: "lock.shield.fill",
                        title: "Sécurité",
                        subtitle: "Paramètres de sécurité",
                        color: AppColors.error
                    )
                }
                
                NavigationLink {
                    NotificationsView()
                        .environmentObject(authViewModel)
                } label: {
                    SettingsOptionRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: "Gérer les notifications",
                        color: AppColors.info
                    )
                }
            }
            
            // Section Support
            Section("Support") {
                NavigationLink {
                    HelpView()
                } label: {
                    SettingsOptionRow(
                        icon: "questionmark.circle.fill",
                        title: "Aide",
                        subtitle: "FAQ et support",
                        color: AppColors.success
                    )
                }
            }
            
            // Section Informations
            Section("Informations") {
                NavigationLink {
                    AboutView()
                } label: {
                    SettingsOptionRow(
                        icon: "info.circle.fill",
                        title: "À propos",
                        subtitle: "Version et informations",
                        color: AppColors.secondaryText
                    )
                }
            }
            
            // Section Déconnexion
            Section {
                Button(role: .destructive) {
                    HapticFeedback.medium()
                    showingSignOutConfirmation = true
                } label: {
                    HStack(spacing: AppDesign.spacingS) {
                        Spacer()
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Déconnexion")
                            .font(AppTypography.body(weight: .semibold))
                        
                        Spacer()
                    }
                    .padding(.vertical, AppDesign.spacingS)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Paramètres")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settingsViewModel.loadSettings()
        }
        .onChange(of: settingsViewModel.errorMessage) { _, error in
            if let error = error {
                notificationAlertMessage = error
                showingNotificationAlert = true
            }
        }
        .alert("Notifications", isPresented: $showingNotificationAlert) {
            Button("Paramètres", role: .none) {
                settingsViewModel.openSystemSettings()
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(notificationAlertMessage)
        }
        .alert("Déconnexion", isPresented: $showingSignOutConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Déconnexion", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
    }
    
    private func signOut() {
        Task {
            // Déconnexion dans AuthViewModel
            await authViewModel.signOut()
            
            // Déconnexion dans AuthManager (nettoie les tokens)
            authManager.signOut()
            
            // Nettoyer aussi ConfigurationService
            ConfigurationService.shared.setAuthToken(nil)
            ConfigurationService.shared.setUserId(nil)
            ConfigurationService.shared.setUserRole(nil)
            
            // La redirection vers AuthGateView se fera automatiquement via RootView
            // car authManager.isAuthenticated sera false
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Settings Option Row

struct SettingsOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône colorée dans un cercle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Titre et sous-titre
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.headline(weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                Text(subtitle)
                    .font(AppTypography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(AuthManager())
    }
}

