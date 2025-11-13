//
//  LocationActivationOverlay.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct LocationActivationOverlay: View {
    let onActivate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Activer la localisation")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Pour trouver les taxis les plus proches, veuillez activer votre localisation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onActivate) {
                    Text("Activer")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        }
    }
}

#Preview {
    LocationActivationOverlay(onActivate: {})
        .padding()
}

