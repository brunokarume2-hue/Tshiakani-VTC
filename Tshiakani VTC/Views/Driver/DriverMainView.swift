//
//  DriverMainView.swift
//  Tshiakani VTC
//
//  Vue principale pour les chauffeurs
//

import SwiftUI

struct DriverMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppDesign.spacingXL) {
                Spacer()
                
                // Illustration
                ZStack {
                    Circle()
                        .fill(AppColors.accentOrange.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "car.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(AppColors.accentOrange)
                }
                .padding(.bottom, AppDesign.spacingL)
                
                // Message informatif
                VStack(spacing: AppDesign.spacingM) {
                    Text("Application Conducteur")
                        .font(AppTypography.largeTitle(weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Les conducteurs utilisent une application séparée dédiée.")
                        .font(AppTypography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppDesign.spacingXL)
                    
                    Text("Cette vue est optionnelle et permet un passage temporaire en mode conducteur si nécessaire.")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppDesign.spacingXL)
                        .padding(.top, AppDesign.spacingS)
                }
                
                Spacer()
            }
            .padding(AppDesign.spacingL)
            .navigationTitle("Mode Conducteur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
        }
    }
}

#Preview {
    DriverMainView()
        .environmentObject(AuthViewModel())
}

