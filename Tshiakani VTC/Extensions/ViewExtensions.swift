//
//  ViewExtensions.swift
//  Tshiakani VTC
//
//  Extensions pour les vues SwiftUI
//

import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    /// Applique un rayon de coin personnalisé sur des coins spécifiques
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Applique un rayon de coin personnalisé sur des coins spécifiques (version avec tableau)
    func cornerRadius(_ radius: CGFloat, corners: [UIRectCorner]) -> some View {
        let combinedCorners = corners.reduce(UIRectCorner(), { $0.union($1) })
        return clipShape(RoundedCorner(radius: radius, corners: combinedCorners))
    }
}

extension UIRectCorner {
    /// Combine deux UIRectCorner en utilisant l'opérateur OR
    func union(_ other: UIRectCorner) -> UIRectCorner {
        return UIRectCorner(rawValue: self.rawValue | other.rawValue)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#else
// Fallback pour les plateformes sans UIKit
extension View {
    func cornerRadius(_ radius: CGFloat, corners: [String]) -> some View {
        self.cornerRadius(radius)
    }
}
#endif

