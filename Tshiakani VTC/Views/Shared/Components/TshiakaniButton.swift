//
//  TshiakaniButton.swift
//  Tshiakani VTC
//
//  Bouton réutilisable avec styles et animations
//

import SwiftUI

enum TshiakaniButtonStyle {
    case primary
    case secondary
    case outline
    case danger
}

struct TshiakaniButton: View {
    let title: String
    let style: TshiakaniButtonStyle
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    
    var body: some View {
        Button(action: {
            // Haptic feedback amélioré avec HapticFeedback
            switch style {
            case .primary:
                HapticFeedback.medium()
            case .danger:
                HapticFeedback.heavy()
            default:
                HapticFeedback.light()
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ModernLoadingView()
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTypography.body())
                        .symbolEffect(.scale, options: .nonRepeating)
                }
                
                Text(title)
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .cornerRadius(AppDesign.cornerRadiusL)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        }
        .buttonStyle(EnhancedButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(AppDesign.animationFast, value: isLoading)
        .animation(AppDesign.animationFast, value: isDisabled)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.clear
                .background(.thinMaterial)
        case .outline:
            Color.clear
        case .danger:
            LinearGradient(
                colors: [AppColors.error, AppColors.error.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary, .danger:
            return .black.opacity(0.2)
        default:
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .danger:
            return 8
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .primary, .danger:
            return 4
        default:
            return 0
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .danger:
            return .white
        case .secondary, .outline:
            return AppColors.primaryText
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return AppColors.accentOrange
        case .secondary:
            return AppColors.border
        case .primary, .danger:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outline:
            return 2
        case .secondary:
            return 1
        default:
            return 0
        }
    }
}

// MARK: - Enhanced Button Style

struct EnhancedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppDesign.animationSnappy, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        TshiakaniButton(
            title: "Continuer",
            style: .primary,
            action: {}
        )
        
        TshiakaniButton(
            title: "Annuler",
            style: .secondary,
            action: {}
        )
        
        TshiakaniButton(
            title: "Charger...",
            style: .primary,
            action: {},
            isLoading: true
        )
        
        TshiakaniButton(
            title: "Supprimer",
            style: .danger,
            action: {},
            icon: "trash.fill"
        )
    }
    .padding()
}

