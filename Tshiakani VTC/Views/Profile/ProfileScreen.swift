//
//  ProfileScreen.swift
//  Tshiakani VTC
//
//  Écran de profil utilisateur avec menu de 9 options
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ProfileScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingImageOptions = false
    @State private var isLoadingImage = false
    @State private var errorMessage: String?
    
    // Données utilisateur depuis AuthViewModel
    private var userName: String {
        authViewModel.currentUser?.name ?? "Utilisateur"
    }
    
    private var userPhone: String {
        authViewModel.currentUser?.phoneNumber ?? ""
    }
    
    // Image de profil
    private var profileImage: UIImage? {
        // D'abord, essayer de charger depuis UserDefaults (image locale)
        if let localImage = ImageService.shared.loadProfileImage() {
            return localImage
        }
        
        // Sinon, essayer de charger depuis profileImageURL du backend
        if let imageURL = authViewModel.currentUser?.profileImageURL {
            // Si c'est une URL base64, la décoder
            if imageURL.hasPrefix("data:image") {
                let components = imageURL.components(separatedBy: ",")
                if components.count == 2 {
                    let base64String = components[1]
                    if let image = ImageService.shared.base64ToImage(base64String) {
                        // Sauvegarder localement pour la prochaine fois
                        ImageService.shared.saveProfileImage(image)
                        return image
                    }
                }
            }
        }
        
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête profil avec identités
                    profileHeader
                        .padding(.bottom, 24)
                }
                .padding()
            }
            .navigationTitle("Profil")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if isLoadingImage {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: AppDesign.spacingL) {
            // Avatar avec photo ou initiale (design moderne inspiré de l'image)
            ZStack {
                // Cercle de fond avec effet de profondeur
                Circle()
                    .fill(AppColors.accentOrange.opacity(0.2))
                    .frame(width: 110, height: 110)
                    .blur(radius: 15)
                
                // Avatar avec photo ou initiale
                if let image = profileImage {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(userName.prefix(1).uppercased())
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // Bouton pour changer la photo (icône caméra en bas à droite)
                Button(action: {
                    showingImageOptions = true
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accentOrange)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 35, y: 35)
            }
            .padding(.top, AppDesign.spacingM)
            .confirmationDialog("Changer la photo de profil", isPresented: $showingImageOptions, titleVisibility: .visible) {
                Button("Prendre une photo", role: .none) {
                    // TODO: Implémenter la caméra
                    showingImagePicker = true
                }
                Button("Choisir depuis la galerie", role: .none) {
                    showingImagePicker = true
                }
                if profileImage != nil {
                    Button("Supprimer la photo", role: .destructive) {
                        deleteProfileImage()
                    }
                }
                Button("Annuler", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showingImagePicker)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    uploadProfileImage(image)
                }
            }
            
            // Nom
            Text(userName)
                .font(AppTypography.largeTitle(weight: .bold))
                .foregroundColor(AppColors.primaryText)
            
            // Identités du client
            VStack(spacing: AppDesign.spacingM) {
                // Numéro de téléphone
                if !userPhone.isEmpty {
                    HStack(spacing: AppDesign.spacingS) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentOrange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.accentOrange)
                        }
                        
                        Text(userPhone)
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingS)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                }
                
                // Email si disponible
                if let email = authViewModel.currentUser?.email, !email.isEmpty {
                    HStack(spacing: AppDesign.spacingS) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentOrange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.accentOrange)
                        }
                        
                        Text(email)
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingS)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppDesign.cornerRadiusM)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppDesign.spacingXL)
        .padding(.horizontal, AppDesign.spacingM)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppDesign.cornerRadiusL)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        isLoadingImage = true
        errorMessage = nil
        
        Task {
            do {
                try await authViewModel.updateProfileImage(image)
                await MainActor.run {
                    isLoadingImage = false
                    selectedImage = nil
                }
            } catch {
                await MainActor.run {
                    isLoadingImage = false
                    errorMessage = "Erreur lors de l'upload de la photo: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteProfileImage() {
        isLoadingImage = true
        errorMessage = nil
        
        Task {
            do {
                try await authViewModel.deleteProfileImage()
                await MainActor.run {
                    isLoadingImage = false
                }
            } catch {
                await MainActor.run {
                    isLoadingImage = false
                    errorMessage = "Erreur lors de la suppression de la photo: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Functional Views

struct PromotionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var promotions: [Promotion] = []
    
    var body: some View {
        List {
            if promotions.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red.opacity(0.5))
                        
                        Text("Aucune promotion active")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Les promotions et codes promo apparaîtront ici lorsqu'ils seront disponibles.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                Section("Promotions actives") {
                    ForEach(promotions) { promotion in
                        PromotionRow(promotion: promotion)
                    }
                }
                
                Section("Codes promo") {
                    Text("Entrez un code promo lors de la commande pour bénéficier d'une réduction.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    // Action pour voir l'historique des promotions
                }) {
                    HStack {
                        Text("Historique des promotions")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.plain)
        #endif
        .navigationTitle("Réductions et cadeaux")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadPromotions()
        }
    }
    
    private func loadPromotions() {
        // TODO: Charger les promotions depuis l'API
        // Pour l'instant, la liste reste vide
        promotions = []
    }
}

struct Promotion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let discount: String
    let expiryDate: Date?
}

struct PromotionRow: View {
    let promotion: Promotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(promotion.title)
                    .font(.headline)
                Spacer()
                Text(promotion.discount)
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Text(promotion.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let expiryDate = promotion.expiryDate {
                Text("Valide jusqu'au \(formatDate(expiryDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct BecomeDriverView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icône
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Titre
                Text("Devenir conducteur")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
                VStack(spacing: 16) {
                    Text("Tshiakani VTC propose une application dédiée pour les conducteurs.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Pour devenir conducteur, veuillez télécharger l'application conducteur depuis l'App Store ou contactez-nous directement.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Informations de contact
                VStack(spacing: 16) {
                    Button(action: {
                        #if os(iOS)
                        if let url = URL(string: "tel://+243900000000") {
                            UIApplication.shared.open(url)
                        }
                        #endif
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Appeler le support")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        #if os(iOS)
                        if let url = URL(string: "mailto:drivers@tshiakanivtc.com") {
                            UIApplication.shared.open(url)
                        }
                        #endif
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Envoyer un email")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Avantages
                VStack(alignment: .leading, spacing: 16) {
                    Text("Avantages de devenir conducteur")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    DriverBenefit(icon: "dollarsign.circle.fill", text: "Revenus flexibles")
                    DriverBenefit(icon: "clock.fill", text: "Horaires flexibles")
                    DriverBenefit(icon: "map.fill", text: "Travaillez dans toute la ville")
                    DriverBenefit(icon: "shield.fill", text: "Assurance et sécurité")
                }
                .padding(.top)
            }
            .padding()
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.05))
        #endif
        .navigationTitle("Devenir conducteur")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct DriverBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color.white)
        #endif
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ProfileScreen()
        .environmentObject(AuthViewModel())
        .environmentObject(AuthManager())
}

