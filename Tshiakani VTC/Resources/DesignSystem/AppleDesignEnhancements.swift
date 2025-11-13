//
//  AppleDesignEnhancements.swift
//  Tshiakani VTC
//
//  Améliorations du design selon les Human Interface Guidelines d'Apple
//  et les meilleures pratiques SwiftUI modernes (iOS 17+)
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Material Effects (iOS 15+)

/// Matériaux système pour les backgrounds avec blur
extension View {
    /// Applique un matériau système ultra-thin
    func ultraThinMaterial() -> some View {
        self.background(.ultraThinMaterial)
    }
    
    /// Applique un matériau système thin
    func thinMaterial() -> some View {
        self.background(.thinMaterial)
    }
    
    /// Applique un matériau système regular
    func regularMaterial() -> some View {
        self.background(.regularMaterial)
    }
    
    /// Applique un matériau système thick
    func thickMaterial() -> some View {
        self.background(.thickMaterial)
    }
    
    /// Applique un matériau système ultra-thick
    func ultraThickMaterial() -> some View {
        self.background(.ultraThickMaterial)
    }
}

// MARK: - Symbol Effects (iOS 17+)

@available(iOS 17.0, *)
extension View {
    /// Applique un effet de pulsation sur un symbole
    func symbolPulse() -> some View {
        self.symbolEffect(.pulse)
    }
    
    /// Applique un effet de rebond sur un symbole
    func symbolBounce() -> some View {
        self.symbolEffect(.bounce)
    }
    
    /// Applique un effet de scale sur un symbole
    func symbolScale() -> some View {
        self.symbolEffect(.scale)
    }
    
    /// Applique un effet de variable color sur un symbole
    func symbolVariableColor() -> some View {
        self.symbolEffect(.variableColor)
    }
}

// MARK: - Enhanced Animations
// Note: Les animations sont définies dans DesignSystem.swift
// Cette section est conservée pour référence mais les animations sont déjà dans AppDesign

// MARK: - Haptic Feedback Enhancer

#if canImport(UIKit)
struct HapticFeedback {
    /// Feedback d'impact léger
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Feedback d'impact moyen
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Feedback d'impact lourd
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Feedback de sélection (pour les pickers)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Feedback de notification (succès/erreur)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Feedback de succès
    static func success() {
        notification(.success)
    }
    
    /// Feedback d'erreur
    static func error() {
        notification(.error)
    }
    
    /// Feedback d'avertissement
    static func warning() {
        notification(.warning)
    }
}
#else
// Fallback pour les plateformes sans UIKit
struct HapticFeedback {
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func selection() {}
    static func notification(_ type: Int) {}
    static func success() {}
    static func error() {}
    static func warning() {}
}
#endif

// MARK: - Safe Area Helpers

extension View {
    /// Ignore les safe areas de manière sélective
    /// Compatible iOS 13+ (utilise edgesIgnoringSafeArea)
    func ignoresSafeAreaSelective(_ edges: Edge.Set = .all) -> some View {
        // Utiliser edgesIgnoringSafeArea qui est disponible depuis iOS 13
        // et fonctionne de la même manière que ignoresSafeArea dans iOS 14+
        return self.edgesIgnoringSafeArea(edges)
    }
}

// MARK: - Adaptive Layout

/// Helper pour créer des layouts adaptatifs selon la taille de l'écran
#if canImport(UIKit)
struct AdaptiveLayout {
    /// Détermine si l'appareil est un iPhone
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Détermine si l'appareil est un iPad
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Détermine si l'appareil est en mode paysage
    static func adaptiveSpacing(_ phone: CGFloat, pad: CGFloat) -> CGFloat {
        isPhone ? phone : pad
    }
    
    /// Détermine la taille adaptative selon l'appareil
    static func adaptiveSize(_ phone: CGFloat, pad: CGFloat) -> CGFloat {
        isPhone ? phone : pad
    }
}
#else
// Fallback pour les plateformes sans UIKit
struct AdaptiveLayout {
    static var isPhone: Bool { true }
    static var isPad: Bool { false }
    static func adaptiveSpacing(_ phone: CGFloat, pad: CGFloat) -> CGFloat { phone }
    static func adaptiveSize(_ phone: CGFloat, pad: CGFloat) -> CGFloat { phone }
}
#endif

// MARK: - Dynamic Type Support

extension View {
    /// Applique un scaling maximum pour Dynamic Type
    func dynamicTypeSize(_ range: DynamicTypeSize...) -> some View {
        if #available(iOS 15.0, *) {
            return self.dynamicTypeSize(range.first!)
        } else {
            return self
        }
    }
    
    /// Limite la taille Dynamic Type pour éviter les layouts cassés
    func limitDynamicTypeSize(max: DynamicTypeSize = .xxxLarge) -> some View {
        if #available(iOS 15.0, *) {
            return self.dynamicTypeSize(...max)
        } else {
            return self
        }
    }
}

// MARK: - Accessibility Enhancements

extension View {
    /// Ajoute un label d'accessibilité avec hint
    func accessibilityLabelWithHint(_ label: String, hint: String) -> some View {
        self.accessibilityLabel(label)
            .accessibilityHint(hint)
    }
    
    /// Ajoute un trait d'accessibilité pour les boutons
    func accessibilityButton() -> some View {
        self.accessibilityAddTraits(.isButton)
    }
    
    /// Ajoute un trait d'accessibilité pour les en-têtes
    func accessibilityHeader() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Modern Button Styles

/// Style de bouton avec matériau et blur
struct MaterialButtonStyle: ButtonStyle {
    let material: Material
    let foregroundColor: Color
    
    init(material: Material = .regularMaterial, foregroundColor: Color = .primary) {
        self.material = material
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16) // AppDesign.spacingM
            .padding(.vertical, 8) // AppDesign.spacingS
            .background(material)
            .cornerRadius(12) // AppDesign.cornerRadiusM
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Loading States

/// Vue de chargement moderne avec animation
public struct ModernLoadingView: View {
    @State private var rotation: Double = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 4)
                .frame(width: 20, height: 20)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

// MARK: - Card Component
// Note: ModernCard est défini dans ModernComponents.swift
// Cette section est conservée pour référence mais ModernCard est dans un autre fichier

// MARK: - Gradient Button

/// Bouton avec gradient et animation
struct GradientButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let cornerRadius: CGFloat
    
    init(
        gradient: LinearGradient = LinearGradient(
            colors: [Color.orange, Color.orange.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        cornerRadius: CGFloat = 16 // AppDesign.cornerRadiusL
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(gradient)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect

/// Effet de shimmer pour les états de chargement
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 200
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12)) // AppDesign.cornerRadiusM
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Interactive Scale

/// Modifier pour ajouter une interaction de scale
struct InteractiveScale: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func interactiveScale() -> some View {
        self.modifier(InteractiveScale())
    }
}

