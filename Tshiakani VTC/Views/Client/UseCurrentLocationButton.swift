//
//  UseCurrentLocationButton.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct UseCurrentLocationButton: View {
    let action: () -> Void
    let isLoading: Bool
    let address: String?
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "location.fill")
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Utiliser ma position")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let address = address, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .opacity(0.9)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.7)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        UseCurrentLocationButton(
            action: {},
            isLoading: false,
            address: "Avenue de la Libération, Kinshasa"
        )
        
        UseCurrentLocationButton(
            action: {},
            isLoading: true,
            address: nil
        )
    }
    .padding()
}

