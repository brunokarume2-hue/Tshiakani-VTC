//
//  TshiakaniLoader.swift
//  Tshiakani VTC
//
//  Loader réutilisable pour les appels réseau
//

import SwiftUI

struct TshiakaniLoader: View {
    var message: String? = nil
    var size: LoaderSize = .medium
    
    enum LoaderSize {
        case small
        case medium
        case large
        
        var scale: CGFloat {
            switch self {
            case .small: return 0.6
            case .medium: return 1.0
            case .large: return 1.4
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                .scaleEffect(size.scale)
            
            if let message = message {
                Text(message)
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
        .padding()
    }
}

struct TshiakaniFullScreenLoader: View {
    var message: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                TshiakaniLoader(message: message, size: .large)
            }
            .padding(32)
            .background(AppColors.background)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        TshiakaniLoader()
        
        TshiakaniLoader(message: "Chargement...", size: .medium)
        
        TshiakaniFullScreenLoader(message: "Recherche de chauffeurs...")
    }
}

