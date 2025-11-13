//
//  TshiakaniPromoCard.swift
//  Tshiakani VTC
//
//  Carte promotionnelle réutilisable
//

import SwiftUI

struct TshiakaniPromoCard: View {
    let title: String
    let message: String
    var icon: String = "gift.fill"
    var gradientColors: [Color] = [AppColors.accentOrange.opacity(0.1), AppColors.accentOrangeLight.opacity(0.1)]
    var borderColor: Color = AppColors.accentOrange.opacity(0.3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accentOrange)
                
                Text(title)
                    .font(AppTypography.title3())
                    .foregroundColor(AppColors.primaryText)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            
            Text(message)
                .font(AppTypography.body())
                .foregroundColor(AppColors.secondaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    TshiakaniPromoCard(
        title: "Offre spéciale",
        message: "Des courses à partir de 34,000 CDF!"
    )
    .padding()
}

