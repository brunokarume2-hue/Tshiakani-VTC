//
//  RideSummaryScreen.swift
//  Tshiakani VTC
//
//  Écran de résumé de course avec évaluation du conducteur
//

import SwiftUI
import CoreLocation

struct RideSummaryScreen: View {
    // MARK: - State
    
    @StateObject private var ratingViewModel = RatingViewModel()
    @StateObject private var alertManager = AlertManager.shared
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Ride à évaluer (peut être nil si appelé depuis un autre contexte)
    let ride: Ride?
    
    // Propriétés calculées depuis RatingViewModel
    private var rating: Int {
        ratingViewModel.rating
    }
    
    private var comment: String {
        ratingViewModel.comment
    }
    
    private var isLoading: Bool {
        ratingViewModel.isLoading
    }
    
    private var selectedTip: Double {
        ratingViewModel.tip
    }
    
    private var customTip: String {
        ratingViewModel.customTip
    }
    
    private var isCustomTip: Bool {
        ratingViewModel.isCustomTip
    }
    
    private var tipOptions: [Double] {
        ratingViewModel.tipOptions
    }
    
    // Données de course calculées depuis le Ride
    private var rideSummary: RideSummary? {
        guard let ride = ride else { return nil }
        
        return RideSummary(
            id: ride.id,
            startAddress: ride.pickupLocation.address ?? "Point de départ",
            endAddress: ride.dropoffLocation.address ?? "Destination",
            duration: formatDuration(ride.duration),
            price: formatPrice(ride.finalPrice ?? ride.estimatedPrice),
            date: ride.completedAt ?? ride.createdAt,
            driver: RideSummaryDriverInfo(
                id: ride.driverId ?? "",
                name: "Chauffeur",
                phone: "",
                plateNumber: "",
                bikeType: "",
                photoURL: nil,
                rating: 0.0,
                currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
        )
    }
    
    init(ride: Ride? = nil) {
        self.ride = ride
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Résumé de la course
                    rideSummarySection
                    
                    // Infos conducteur
                    driverInfoSection
                    
                    // Évaluation
                    ratingSection
                    
                    // Pourboire
                    tipSection
                    
                    // Commentaire
                    commentSection
                    
                    // Boutons d'action
                    actionButtons
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Course terminée")
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .tshiakaniAlert()
            .background(AppColors.background)
            .onAppear {
                // Charger les données de la course si disponible
                if let ride = ride {
                    Task {
                        await ratingViewModel.loadRide(rideId: ride.id)
                        // Charger les informations du conducteur si disponible
                        if let driverId = ride.driverId {
                            await loadDriverInfo(driverId: driverId)
                        }
                    }
                }
            }
            .onChange(of: ratingViewModel.errorMessage) { _, error in
                if let error = error {
                    alertManager.showError(
                        title: "Erreur",
                        message: error
                    )
                }
            }
        }
    }
    
    // MARK: - Header Section (inspiré de l'image)
    
    private var headerSection: some View {
        VStack(spacing: AppDesign.spacingM) {
            // Grande icône de succès avec effet
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.success.opacity(0.2), AppColors.success.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundColor(AppColors.success)
            }
            .padding(.top, AppDesign.spacingL)
            
            Text("Vous êtes arrivé à destination !")
                .font(AppTypography.largeTitle(weight: .bold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppDesign.spacingXL)
    }
    
    // MARK: - Ride Summary Section
    
    private var rideSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Résumé de la course")
                .font(AppTypography.headline())
                .foregroundColor(AppColors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            VStack(spacing: 12) {
                // Départ
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.success)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Départ")
                            .font(AppTypography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text(rideSummary?.startAddress ?? "Point de départ")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.primaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Destination
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.error)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Destination")
                            .font(AppTypography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text(rideSummary?.endAddress ?? "Destination")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.primaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Durée et Prix
                HStack {
                    Label(rideSummary?.duration ?? "0 min", systemImage: "clock.fill")
                        .font(AppTypography.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    Spacer()
                    
                    Text(rideSummary?.price ?? "0 FC")
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Driver Info Section
    
    private var driverInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Votre conducteur")
                .font(AppTypography.headline())
                .foregroundColor(AppColors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            HStack(spacing: 16) {
                // Photo
                AsyncImage(url: rideSummary?.driver.photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
                
                // Informations
                VStack(alignment: .leading, spacing: 6) {
                    Text(rideSummary?.driver.name ?? "Chauffeur")
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    if let plateNumber = rideSummary?.driver.plateNumber, !plateNumber.isEmpty {
                        HStack(spacing: 8) {
                            Label(plateNumber, systemImage: "number")
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.secondaryText)
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            
                            if let bikeType = rideSummary?.driver.bikeType, !bikeType.isEmpty {
                                Text("•")
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text(bikeType)
                                    .font(AppTypography.caption())
                                    .foregroundColor(AppColors.secondaryText)
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            }
                        }
                    }
                    
                    if let rating = rideSummary?.driver.rating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accentOrange)
                            
                            Text(String(format: "%.1f", rating))
                                .font(AppTypography.caption())
                                .foregroundColor(AppColors.secondaryText)
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AppDesign.spacingM)
            .background(.thinMaterial)
            .cornerRadius(AppDesign.cornerRadiusL)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Rating Section (inspiré de l'image)
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingM) {
            Text("Comment s'est passé le trajet ?")
                .font(AppTypography.headline(weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            VStack(spacing: AppDesign.spacingM) {
                TshiakaniRatingStars(
                    rating: Binding(
                        get: { ratingViewModel.rating },
                        set: { ratingViewModel.rating = $0 }
                    ),
                    starSize: 50
                )
                
                if ratingViewModel.rating > 0 {
                    Text(ratingText)
                        .font(AppTypography.subheadline(weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                        .padding(.top, AppDesign.spacingS)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppDesign.spacingL)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppDesign.cornerRadiusL)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Tip Section (inspiré de l'image)
    
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingM) {
            Text("Soutenez le chauffeur")
                .font(AppTypography.headline(weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            // Options de pourboire
            HStack(spacing: AppDesign.spacingS) {
                ForEach(ratingViewModel.tipOptions, id: \.self) { tip in
                    TipButton(
                        amount: tip,
                        isSelected: ratingViewModel.tip == tip && !ratingViewModel.isCustomTip,
                        isCustom: tip == ratingViewModel.tipOptions.last
                    ) {
                        Task {
                            await ratingViewModel.selectTip(tip)
                        }
                    }
                }
            }
            
            // Champ de pourboire personnalisé
            if ratingViewModel.isCustomTip {
                TextField("Montant personnalisé (FC)", text: Binding(
                    get: { ratingViewModel.customTip },
                    set: { ratingViewModel.setCustomTip($0) }
                ))
                .keyboardType(.numberPad)
                .font(AppTypography.body())
                .padding(AppDesign.spacingM)
                .background(.thinMaterial)
                .cornerRadius(AppDesign.cornerRadiusM)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                        .stroke(AppColors.accentOrange, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Tip Button
    
    private struct TipButton: View {
        let amount: Double
        let isSelected: Bool
        let isCustom: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: {
                HapticFeedback.selection()
                withAnimation(AppDesign.animationSnappy) {
                    action()
                }
            }) {
                Text(isCustom ? "Custom" : "\(Int(amount)) FC")
                    .font(AppTypography.subheadline(weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppColors.primaryText)
                    .padding(.horizontal, AppDesign.spacingM)
                    .padding(.vertical, AppDesign.spacingS)
                    .frame(minWidth: 70)
                    .background(backgroundView)
                    .cornerRadius(AppDesign.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                            .stroke(
                                isSelected ? Color.clear : AppColors.border.opacity(0.3),
                                lineWidth: isSelected ? 0 : 1
                            )
                    )
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            }
            .buttonStyle(EnhancedButtonStyle())
            .animation(AppDesign.animationSnappy, value: isSelected)
        }
        
        @ViewBuilder
        private var backgroundView: some View {
            if isSelected {
                LinearGradient(
                    colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
                    .background(.thinMaterial)
            }
        }
        
        private var shadowColor: Color {
            isSelected ? .black.opacity(0.15) : .clear
        }
        
        private var shadowRadius: CGFloat {
            isSelected ? 4 : 0
        }
        
        private var shadowY: CGFloat {
            isSelected ? 2 : 0
        }
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Très déçu"
        case 2: return "Déçu"
        case 3: return "Correct"
        case 4: return "Très bien"
        case 5: return "Excellent !"
        default: return ""
        }
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a comment for the driver...")
                .font(AppTypography.caption())
                .foregroundColor(AppColors.secondaryText)
            
            TextEditor(text: Binding(
                get: { ratingViewModel.comment },
                set: { ratingViewModel.comment = $0 }
            ))
            .frame(height: 100)
            .padding(AppDesign.spacingS)
            .background(.thinMaterial)
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Bouton "Payer en ligne" (design moderne)
            Button(action: {
                HapticFeedback.medium()
                submitRating(withPayment: true)
            }) {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Payer en ligne")
                        .font(AppTypography.headline(weight: .semibold))
                }
                .foregroundColor(AppColors.accentOrange)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                        .stroke(AppColors.accentOrange, lineWidth: 2)
                )
                .cornerRadius(AppDesign.cornerRadiusL)
            }
            .buttonStyle(EnhancedButtonStyle())
            .accessibilityLabel("Payer en ligne")
            .accessibilityHint("Compléter le paiement en ligne")
            
            // Bouton "Déjà payé ? Compléter maintenant" (design moderne)
            Button(action: {
                HapticFeedback.medium()
                submitRating(withPayment: false)
            }) {
                HStack(spacing: AppDesign.spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Déjà payé ? Compléter maintenant")
                        .font(AppTypography.headline(weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppDesign.cornerRadiusL)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(EnhancedButtonStyle())
            .accessibilityLabel("Compléter maintenant")
            .accessibilityHint("Compléter l'évaluation si déjà payé")
            .disabled(ratingViewModel.rating == 0 || ratingViewModel.isLoading)
            .opacity((ratingViewModel.rating == 0 || ratingViewModel.isLoading) ? 0.6 : 1.0)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func submitRating(withPayment: Bool) {
        guard let rideId = ride?.id else {
            alertManager.showError(
                title: "Erreur",
                message: "Impossible de trouver la course"
            )
            return
        }
        
        Task {
            let success = await ratingViewModel.submitRating(
                rideId: rideId,
                rating: ratingViewModel.rating > 0 ? ratingViewModel.rating : 5,
                comment: ratingViewModel.comment.isEmpty ? nil : ratingViewModel.comment,
                tip: ratingViewModel.tip > 0 ? ratingViewModel.tip : nil,
                withPayment: withPayment
            )
            
            if success {
                await MainActor.run {
                    alertManager.showSuccess(
                        title: "Merci pour votre retour !",
                        message: "Votre évaluation a été enregistrée."
                    ) {
                        dismiss()
                    }
                }
            } else {
                await MainActor.run {
                    alertManager.showError(
                        title: "Erreur",
                        message: ratingViewModel.errorMessage ?? "Impossible d'enregistrer l'évaluation"
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "0 min" }
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    private func formatPrice(_ price: Double) -> String {
        return "\(Int(price)) FC"
    }
    
    private func loadDriverInfo(driverId: String) async {
        do {
            let driver = try await APIService.shared.getUser(id: driverId)
            // Les informations du conducteur seront utilisées dans rideSummary
            // Note: Le modèle RideSummary utilise déjà les données du Ride qui contient driverId
        } catch {
            print("Erreur lors du chargement des informations du conducteur: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct RideSummary {
    let id: String
    let startAddress: String
    let endAddress: String
    let duration: String
    let price: String
    let date: Date
    let driver: RideSummaryDriverInfo
}

struct RideSummaryDriverInfo {
    let id: String
    let name: String
    let phone: String
    let plateNumber: String
    let bikeType: String
    let photoURL: URL?
    let rating: Double
    var currentLocation: CLLocationCoordinate2D
}

#Preview {
    RideSummaryScreen()
}

