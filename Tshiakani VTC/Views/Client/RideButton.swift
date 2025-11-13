//
//  RideButton.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct RideButton: View {
    let action: () -> Void
    let currentAddress: String?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Où et pour combien ?")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                
                if let address = currentAddress, !address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(address)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.accentOrange,
                        AppColors.accentOrange.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: AppColors.accentOrange.opacity(0.4), radius: 15, x: 0, y: 8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RideButton(
            action: {},
            currentAddress: "Avenue de la Libération, Kinshasa"
        )
        
        RideButton(
            action: {},
            currentAddress: nil
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

