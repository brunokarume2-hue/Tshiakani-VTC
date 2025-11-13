//
//  CarrierInfoView.swift
//  Tshiakani VTC
//
//  Vue pour afficher les informations du transporteur
//

import SwiftUI

struct CarrierInfoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supportViewModel = SupportViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.spacingL) {
                    // En-tête
                    VStack(spacing: AppDesign.spacingS) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accentOrange)
                        
                        Text("Transporteur")
                            .font(AppTypography.headline(weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text(supportViewModel.carrierName)
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.top, AppDesign.spacingXL)
                    
                    // Informations
                    VStack(alignment: .leading, spacing: AppDesign.spacingM) {
                        InfoRow(
                            icon: "phone.fill",
                            title: "Téléphone",
                            value: supportViewModel.carrierPhoneNumber
                        )
                        
                        InfoRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: supportViewModel.carrierEmail
                        )
                        
                        InfoRow(
                            icon: "map.fill",
                            title: "Adresse",
                            value: supportViewModel.carrierAddress
                        )
                        
                        InfoRow(
                            icon: "clock.fill",
                            title: "Horaires",
                            value: supportViewModel.carrierHours
                        )
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    
                    Spacer()
                }
            }
            .navigationTitle("Transporteur et coordonnées")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: AppDesign.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.accentOrange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.caption())
                    .foregroundColor(AppColors.secondaryText)
                
                Text(value)
                    .font(AppTypography.body())
                    .foregroundColor(AppColors.primaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, AppDesign.spacingS)
    }
}

#Preview {
    CarrierInfoView()
}

