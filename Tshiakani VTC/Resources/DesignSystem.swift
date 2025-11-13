//
//  DesignSystem.swift
//  Tshiakani VTC
//
//  Système de design conforme aux Human Interface Guidelines d'Apple
//

import SwiftUI

/// Système de design avec espacements, ombres et styles conformes aux guidelines Apple
struct AppDesign {
    // MARK: - Espacements (selon guidelines Apple)
    
    /// Espacement minimal (4pt)
    static let spacingXS: CGFloat = 4
    
    /// Espacement petit (8pt)
    static let spacingS: CGFloat = 8
    
    /// Espacement moyen (16pt)
    static let spacingM: CGFloat = 16
    
    /// Espacement large (24pt)
    static let spacingL: CGFloat = 24
    
    /// Espacement extra large (32pt)
    static let spacingXL: CGFloat = 32
    
    /// Espacement très large (48pt)
    static let spacingXXL: CGFloat = 48
    
    // MARK: - Rayons de coin (selon guidelines Apple)
    
    /// Petit rayon (8pt)
    static let cornerRadiusS: CGFloat = 8
    
    /// Rayon moyen (12pt)
    static let cornerRadiusM: CGFloat = 12
    
    /// Rayon large (16pt)
    static let cornerRadiusL: CGFloat = 16
    
    /// Rayon extra large (20pt)
    static let cornerRadiusXL: CGFloat = 20
    
    // MARK: - Ombres (selon guidelines Apple)
    
    /// Ombre discrète pour les cartes
    static func cardShadow() -> some ViewModifier {
        ShadowModifier(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    /// Ombre moyenne pour les boutons
    static func buttonShadow() -> some ViewModifier {
        ShadowModifier(
            color: Color.black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
    }
    
    /// Ombre prononcée pour les modals
    static func modalShadow() -> some ViewModifier {
        ShadowModifier(
            color: Color.black.opacity(0.2),
            radius: 20,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Styles de boutons
    
    /// Style de bouton primaire avec haptic feedback
    static func primaryButtonStyle() -> some ButtonStyle {
        PrimaryButtonStyle()
    }
    
    /// Style de bouton secondaire
    static func secondaryButtonStyle() -> some ButtonStyle {
        SecondaryButtonStyle()
    }
    
    // MARK: - Animations (selon guidelines Apple)
    
    /// Animation rapide (0.2s)
    static let animationFast = Animation.easeInOut(duration: 0.2)
    
    /// Animation standard (0.3s)
    static let animationStandard = Animation.spring(response: 0.3, dampingFraction: 0.8)
    
    /// Animation lente (0.5s)
    static let animationSlow = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// Animation spring avec bounce pour les interactions
    static let animationBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)
    
    /// Animation smooth pour les transitions
    static let animationSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)
    
    /// Animation snappy pour les feedbacks rapides
    static let animationSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
}

// MARK: - Modifiers d'ombre

struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Styles de boutons

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(AppDesign.animationFast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppDesign.animationFast, value: configuration.isPressed)
    }
}

// MARK: - Extensions utiles

extension View {
    /// Applique une ombre de carte
    func cardShadow() -> some View {
        self.modifier(AppDesign.cardShadow())
    }
    
    /// Applique une ombre de bouton
    func buttonShadow() -> some View {
        self.modifier(AppDesign.buttonShadow())
    }
    
    /// Applique une ombre de modal
    func modalShadow() -> some View {
        self.modifier(AppDesign.modalShadow())
    }
    
    /// Applique un style de bouton primaire
    func primaryButtonStyle() -> some View {
        self.buttonStyle(AppDesign.primaryButtonStyle())
    }
    
    /// Applique un style de bouton secondaire
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(AppDesign.secondaryButtonStyle())
    }
}

