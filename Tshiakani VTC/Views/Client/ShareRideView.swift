//
//  ShareRideView.swift
//  Tshiakani VTC
//
//  Fonctionnalité de partage de trajet
//

import SwiftUI

struct ShareRideView: View {
    let ride: Ride
    @Environment(\.dismiss) var dismiss
    @StateObject private var shareViewModel = ShareViewModel()
    @State private var shareSheetPresented = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppDesign.spacingXL) {
                Spacer()
                
                // Icône de partage
                ZStack {
                    Circle()
                        .fill(AppColors.accentOrange.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                }
                .padding(.bottom, AppDesign.spacingL)
                
                // Informations du trajet
                VStack(spacing: AppDesign.spacingM) {
                    Text("Partager votre trajet")
                        .font(AppTypography.largeTitle(weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Partagez les détails de votre trajet avec vos proches")
                        .font(AppTypography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppDesign.spacingXL)
                }
                
                // Détails du trajet
                VStack(spacing: AppDesign.spacingM) {
                    RideDetailRow(
                        icon: "mappin.circle.fill",
                        title: "Départ",
                        value: ride.pickupLocation.address ?? "Point de départ",
                        color: AppColors.success
                    )
                    
                    RideDetailRow(
                        icon: "flag.circle.fill",
                        title: "Destination",
                        value: ride.dropoffLocation.address ?? "Destination",
                        color: AppColors.accentOrange
                    )
                    
                    if let distance = ride.distance {
                        RideDetailRow(
                            icon: "ruler.fill",
                            title: "Distance",
                            value: String(format: "%.1f km", distance),
                            color: AppColors.info
                        )
                    }
                    
                    RideDetailRow(
                        icon: "dollarsign.circle.fill",
                        title: "Prix",
                        value: "\(Int(ride.estimatedPrice)) FC",
                        color: AppColors.accentOrange
                    )
                }
                .padding(AppDesign.spacingM)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppDesign.cornerRadiusL)
                .padding(.horizontal, AppDesign.spacingM)
                
                Spacer()
                
                // Options de partage
                VStack(spacing: AppDesign.spacingM) {
                    ShareButton(
                        icon: "message.fill",
                        title: "Partager par message",
                        color: AppColors.info
                    ) {
                        shareViaMessage()
                    }
                    
                    ShareButton(
                        icon: "mail.fill",
                        title: "Partager par email",
                        color: AppColors.accentOrange
                    ) {
                        shareViaEmail()
                    }
                    
                    ShareButton(
                        icon: "square.and.arrow.up",
                        title: "Autres options",
                        color: AppColors.primaryText
                    ) {
                        shareSheetPresented = true
                    }
                    
                    if shareViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                            .padding()
                    }
                }
                .padding(.horizontal, AppDesign.spacingM)
                .padding(.bottom, AppDesign.spacingL)
            }
            .background(AppColors.background)
            .navigationTitle("Partager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
            .sheet(isPresented: $shareSheetPresented) {
                RideShareSheet(items: [generateShareText()])
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(shareViewModel.errorMessage ?? "Une erreur est survenue")
            }
            .onChange(of: shareViewModel.errorMessage) { _, error in
                if error != nil {
                    showingError = true
                }
            }
        }
    }
    
    private func generateShareText() -> String {
        var text = "🚗 Trajet Tshiakani VTC\n\n"
        text += "📍 Départ: \(ride.pickupLocation.address ?? "Point de départ")\n"
        text += "🎯 Destination: \(ride.dropoffLocation.address ?? "Destination")\n"
        if let distance = ride.distance {
            text += "📏 Distance: \(String(format: "%.1f km", distance))\n"
        }
        text += "💰 Prix: \(Int(ride.estimatedPrice)) FC\n"
        text += "🆔 ID de course: \(ride.id)\n\n"
        if let shareLink = shareViewModel.shareLink {
            text += "🔗 Lien de partage: \(shareLink)\n\n"
        }
        text += "Téléchargez Tshiakani VTC pour réserver vos trajets!"
        return text
    }
    
    private func shareViaMessage() {
        Task {
            // Générer le lien de partage
            if let link = await shareViewModel.generateShareLink(rideId: ride.id) {
                let text = generateShareText()
                if let url = URL(string: "sms:&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    #if os(iOS)
                    await UIApplication.shared.open(url)
                    #endif
                }
            }
        }
    }
    
    private func shareViaEmail() {
        let text = generateShareText()
        if let url = URL(string: "mailto:?subject=Trajet Tshiakani VTC&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            Task {
                #if os(iOS)
                await UIApplication.shared.open(url)
                #endif
            }
        }
    }
}

struct RideDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppDesign.spacingM) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(AppTypography.subheadline())
                .foregroundColor(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.subheadline(weight: .semibold))
                .foregroundColor(AppColors.primaryText)
        }
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppDesign.spacingM) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTypography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(AppDesign.spacingM)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppDesign.cornerRadiusM)
        }
        .buttonStyle(.plain)
    }
}

struct RideShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareRideView(ride: Ride(
        clientId: "client123",
        pickupLocation: Location(latitude: -4.3276, longitude: 15.3136, address: "Point de départ"),
        dropoffLocation: Location(latitude: -4.3500, longitude: 15.3200, address: "Destination"),
        estimatedPrice: 5000
    ))
}

