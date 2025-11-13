//
//  SocialLoginButton.swift
//  Tshiakani VTC
//
//  Bouton de connexion sociale (Google, Facebook, X)
//

import SwiftUI

struct SocialLoginButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            Circle()
                .fill(AppColors.secondaryBackground)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        SocialLoginButton(icon: "globe", color: AppColors.info) {}
        SocialLoginButton(icon: "f.circle.fill", color: AppColors.info) {}
        SocialLoginButton(icon: "xmark", color: AppColors.primaryText) {}
    }
    .padding()
}

