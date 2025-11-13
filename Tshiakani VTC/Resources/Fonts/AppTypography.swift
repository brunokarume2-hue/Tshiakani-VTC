//
//  AppTypography.swift
//  Tshiakani VTC
//
//  Système typographique avec support Dynamic Type
//

import SwiftUI

/// Système typographique utilisant SF Pro avec support complet de Dynamic Type
struct AppTypography {
    // MARK: - Titres
    
    /// Grand titre (utilise .largeTitle avec Dynamic Type)
    static func largeTitle(weight: Font.Weight = .bold) -> Font {
        .system(.largeTitle, design: .default, weight: weight)
    }
    
    /// Titre 1 (utilise .title avec Dynamic Type)
    static func title1(weight: Font.Weight = .bold) -> Font {
        .system(.title, design: .default, weight: weight)
    }
    
    /// Titre 2 (utilise .title2 avec Dynamic Type)
    static func title2(weight: Font.Weight = .semibold) -> Font {
        .system(.title2, design: .default, weight: weight)
    }
    
    /// Titre 3 (utilise .title3 avec Dynamic Type)
    static func title3(weight: Font.Weight = .semibold) -> Font {
        .system(.title3, design: .default, weight: weight)
    }
    
    // MARK: - Corps de texte
    
    /// Corps de texte principal (utilise .body avec Dynamic Type)
    static func body(weight: Font.Weight = .regular) -> Font {
        .system(.body, design: .default, weight: weight)
    }
    
    /// Corps de texte en gras
    static func bodyBold() -> Font {
        .system(.body, design: .default, weight: .semibold)
    }
    
    // MARK: - Textes secondaires
    
    /// Texte de tête (utilise .headline avec Dynamic Type)
    static func headline(weight: Font.Weight = .semibold) -> Font {
        .system(.headline, design: .default, weight: weight)
    }
    
    /// Sous-titre (utilise .subheadline avec Dynamic Type)
    static func subheadline(weight: Font.Weight = .regular) -> Font {
        .system(.subheadline, design: .default, weight: weight)
    }
    
    // MARK: - Textes petits
    
    /// Note (utilise .footnote avec Dynamic Type)
    static func footnote(weight: Font.Weight = .regular) -> Font {
        .system(.footnote, design: .default, weight: weight)
    }
    
    /// Légende (utilise .caption avec Dynamic Type)
    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(.caption, design: .default, weight: weight)
    }
    
    /// Légende 2 (utilise .caption2 avec Dynamic Type)
    static func caption2(weight: Font.Weight = .regular) -> Font {
        .system(.caption2, design: .default, weight: weight)
    }
}

// MARK: - View Modifiers pour typographie

extension View {
    /// Applique un style de texte avec Dynamic Type
    func appTextStyle(_ style: AppTextStyle) -> some View {
        self.modifier(AppTextStyleModifier(style: style))
    }
}

enum AppTextStyle {
    case largeTitle, title1, title2, title3
    case headline, body, subheadline
    case footnote, caption, caption2
}

struct AppTextStyleModifier: ViewModifier {
    let style: AppTextStyle
    
    func body(content: Content) -> some View {
        content
            .font(fontForStyle(style))
    }
    
    private func fontForStyle(_ style: AppTextStyle) -> Font {
        switch style {
        case .largeTitle: return AppTypography.largeTitle()
        case .title1: return AppTypography.title1()
        case .title2: return AppTypography.title2()
        case .title3: return AppTypography.title3()
        case .headline: return AppTypography.headline()
        case .body: return AppTypography.body()
        case .subheadline: return AppTypography.subheadline()
        case .footnote: return AppTypography.footnote()
        case .caption: return AppTypography.caption()
        case .caption2: return AppTypography.caption2()
        }
    }
}

