//
//  TshiakaniDestinationTile.swift
//  Tshiakani VTC
//
//  Tuile de destination réutilisable
//

import SwiftUI

struct TshiakaniDestinationTile: View {
    let name: String
    let eta: String
    let price: String
    var icon: String = "mappin.circle.fill"
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primaryBlue)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.leading)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    HStack(spacing: 12) {
                        Label(eta, systemImage: "clock.fill")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text("•")
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(price)
                            .font(AppTypography.subheadline(weight: .medium))
                            .foregroundColor(AppColors.success)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        TshiakaniDestinationTile(
            name: "Aéroport de N'Djili",
            eta: "25 min",
            price: "45,000 CDF"
        )
        
        TshiakaniDestinationTile(
            name: "Gombe",
            eta: "15 min",
            price: "34,000 CDF"
        )
    }
    .padding()
}

