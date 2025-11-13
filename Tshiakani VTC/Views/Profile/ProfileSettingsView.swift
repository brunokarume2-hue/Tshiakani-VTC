//
//  ProfileSettingsView.swift
//  Tshiakani VTC
//
//  Écran de Profil/Paramètres conforme aux Apple Human Interface Guidelines
//  Remplace la navigation latérale par un écran standard iOS
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingSignOutConfirmation = false
    @State private var showingEditProfile = false
    
    var body: some View {
        List {
            // Section Profil (en-tête avec avatar centré - style Image 4)
            Section {
                profileHeaderView
                    .onTapGesture {
                        showingEditProfile = true
                    }
            }
            .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            .listRowBackground(Color.clear)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
            
            // Options principales (simplifiées - MVP)
            Section {
                NavigationLink {
                    RideHistoryView()
                        .environmentObject(authViewModel)
                } label: {
                    ProfileMenuItem(
                        icon: "clock.fill",
                        title: "Historique",
                        color: AppColors.accentOrange
                    )
                }
                
                NavigationLink {
                    SettingsView()
                        .environmentObject(authViewModel)
                        .environmentObject(authManager)
                } label: {
                    ProfileMenuItem(
                        icon: "gearshape.fill",
                        title: "Paramètres",
                        color: AppColors.accentOrange
                    )
                }
                
                NavigationLink {
                    HelpView()
                } label: {
                    ProfileMenuItem(
                        icon: "questionmark.circle.fill",
                        title: "Aide",
                        color: AppColors.accentOrange
                    )
                }
            }
            
            // Déconnexion
            Section {
                Button(role: .destructive) {
                    showingSignOutConfirmation = true
                } label: {
                    HStack(spacing: AppDesign.spacingM) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        Text("Déconnexion")
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, AppDesign.spacingS)
                }
            }
        }
        .listStyle(.insetGrouped) // Style iOS natif HIG (comme Image 4)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Charger le profil utilisateur
            profileViewModel.loadUserProfile()
        }
        .onChange(of: profileViewModel.currentUser) { _, user in
            // Mettre à jour authViewModel si nécessaire
            if let user = user {
                authViewModel.currentUser = user
            }
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
            await authViewModel.signOut()
            authManager.signOut()
        }
    }
    
    // MARK: - Profile Header View (amélioré avec Apple Design)
    private var profileHeaderView: some View {
        VStack(spacing: AppDesign.spacingM) {
            // Avatar circulaire avec gradient et ombre
            ZStack {
                // Cercle de fond avec blur
                Circle()
                    .fill(AppColors.accentOrange.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                // Avatar principal avec gradient ou image
                if let profileImage = profileViewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text((profileViewModel.currentUser?.name ?? authViewModel.currentUser?.name ?? "U").prefix(1).uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }
            
            // Nom de l'utilisateur
            Text(profileViewModel.currentUser?.name ?? authViewModel.currentUser?.name ?? "Utilisateur")
                .font(AppTypography.title3(weight: .semibold))
                .foregroundColor(.primary)
            
            // Numéro de téléphone
            let phoneNumber = profileViewModel.currentUser?.phoneNumber ?? authViewModel.currentUser?.phoneNumber
            if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
                Text(phoneNumber)
                    .font(AppTypography.subheadline())
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppDesign.spacingM)
    }
}

// MARK: - Profile Menu Item (amélioré avec Apple Design)
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppDesign.spacingM) {
            // Icône avec fond coloré et gradient
            ZStack {
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Titre
            Text(title)
                .font(AppTypography.body(weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, AppDesign.spacingS)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileSettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(AuthManager())
}

