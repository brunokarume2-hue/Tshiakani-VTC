//
//  RideRequestButton.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct RideRequestButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let currentAddress: String?
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            action()
        }) {
            VStack(spacing: AppDesign.spacingS) {
                HStack(spacing: AppDesign.spacingM) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .symbolEffect(.bounce, value: isEnabled)
                    
                    Text("Où et pour combien ?")
                        .font(AppTypography.headline(weight: .bold))
                }
                .foregroundColor(.white)
                
                if let address = currentAddress, !address.isEmpty {
                    HStack(spacing: AppDesign.spacingXS) {
                        Image(systemName: "mappin.circle.fill")
                            .font(AppTypography.caption())
                        Text(address)
                            .font(AppTypography.caption())
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppDesign.spacingL)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient(
                            colors: [
                                AppColors.accentOrange,
                                AppColors.accentOrange.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                AppColors.secondaryText.opacity(0.3),
                                AppColors.secondaryText.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .cornerRadius(AppDesign.cornerRadiusXL)
            .shadow(
                color: isEnabled ? AppColors.accentOrange.opacity(0.3) : Color.clear,
                radius: isEnabled ? 12 : 0,
                x: 0,
                y: isEnabled ? 6 : 0
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .buttonStyle(AppDesign.primaryButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        RideRequestButton(
            action: {},
            isEnabled: true,
            currentAddress: "Avenue de la Libération, Kinshasa"
        )
        
        RideRequestButton(
            action: {},
            isEnabled: false,
            currentAddress: nil
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

