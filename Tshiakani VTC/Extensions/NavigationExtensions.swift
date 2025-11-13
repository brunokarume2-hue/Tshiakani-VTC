//
//  NavigationExtensions.swift
//  Tshiakani VTC
//
//  Extensions pour NavigationStack avec transitions douces
//

import SwiftUI

// MARK: - NavigationStack avec transitions personnalisées

extension View {
    /// Navigation avec transition douce (utilise navigationDestination pour iOS 16+)
    @available(iOS 16.0, *)
    func smoothNavigation<Destination: View>(
        isActive: Binding<Bool>,
        destination: @escaping () -> Destination
    ) -> some View {
        self.navigationDestination(isPresented: isActive) {
            destination()
        }
    }
}

// MARK: - Modifier pour transitions personnalisées

struct SmoothTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}

extension View {
    func smoothTransition() -> some View {
        self.modifier(SmoothTransitionModifier())
    }
}

// MARK: - NavigationButton Style

struct NavigationButtonStyle: ButtonStyle {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 16) {
        self.spacing = spacing
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, spacing)
            .padding(.vertical, spacing / 2)
            .background(configuration.isPressed ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NavigationButtonStyle {
    static func navigation(spacing: CGFloat = 16) -> NavigationButtonStyle {
        NavigationButtonStyle(spacing: spacing)
    }
}

