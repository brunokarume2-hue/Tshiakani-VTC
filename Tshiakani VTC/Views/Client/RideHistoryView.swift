//
//  RideHistoryView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct RideHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var rideViewModel = RideViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if rideViewModel.rideHistory.isEmpty {
                    // État vide amélioré (style Bolt)
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Aucun trajet")
                                .font(AppTypography.title3(weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Vos courses apparaîtront ici")
                                .font(AppTypography.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(rideViewModel.rideHistory) { ride in
                        RideHistoryRow(ride: ride)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let userId = authViewModel.currentUser?.id {
                await rideViewModel.loadRideHistory(userId: userId)
            }
        }
    }
}

struct RideHistoryRow: View {
    let ride: Ride
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône simple (style Bolt)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.accentOrange.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.accentOrange)
            }
            
            // Informations de course
            VStack(alignment: .leading, spacing: 8) {
                // Date et heure
                Text(formatDate(ride.createdAt))
                    .font(AppTypography.caption(weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
                
                // Adresse de départ
                Text(ride.pickupLocation.address ?? "Point de départ")
                    .font(AppTypography.subheadline(weight: .regular))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                // Adresse de destination
                Text(ride.dropoffLocation.address ?? "Destination")
                    .font(AppTypography.subheadline(weight: .regular))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Prix à droite
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(ride.finalPrice ?? ride.estimatedPrice)) FC")
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(AppColors.accentOrange)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Aujourd'hui, \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInYesterday(date) {
            return "Hier, \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, HH:mm"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        RideHistoryView()
            .environmentObject(AuthViewModel())
    }
}
