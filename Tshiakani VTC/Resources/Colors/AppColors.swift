//
//  AppColors.swift
//  Tshiakani VTC
//
//  Palette de couleurs avec contraste élevé pour accessibilité
//

import SwiftUI

/// Palette de couleurs de l'application avec support du mode sombre et contraste élevé
struct AppColors {
    // MARK: - Couleurs Principales
    
    /// Rouge vif pour le branding (conforme WCAG AA)
    static let primaryRed = Color(red: 1.0, green: 0.0, blue: 0.0)
    
    /// Bleu pour les actions principales (conforme WCAG AA)
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    /// Orange principal pour le branding (conforme WCAG AA et normes Apple)
    /// Couleur primaire: Orange vif et distinctif (#FF8C00 - Orange Vif)
    static let accentOrange = Color(red: 1.0, green: 0.55, blue: 0.0) // #FF8C00
    
    /// Orange doux pour les fonds et accents légers (conforme aux guidelines Apple)
    static let accentOrangeLight = Color(red: 1.0, green: 0.95, blue: 0.9)
    
    /// Orange très clair pour les backgrounds subtils
    static let accentOrangeVeryLight = Color(red: 1.0, green: 0.98, blue: 0.95)
    
    /// Orange foncé pour les états hover/pressed
    static let accentOrangeDark = Color(red: 0.9, green: 0.48, blue: 0.0)
    
    // MARK: - Couleurs Sémantiques
    
    /// Vert pour les états de succès
    static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
    
    /// Rouge pour les erreurs
    static let error = Color(red: 1.0, green: 0.23, blue: 0.19)
    
    /// Orange pour les avertissements
    static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
    
    /// Gris pour les informations
    static let info = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    // MARK: - Couleurs de Fond
    
    /// Fond principal (s'adapte au mode sombre)
    static let background = Color(.systemBackground)
    
    /// Fond secondaire (s'adapte au mode sombre)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// Fond tertiaire (s'adapte au mode sombre)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Couleurs de Texte
    
    /// Texte principal (s'adapte au mode sombre)
    static let primaryText = Color(.label)
    
    /// Texte secondaire (s'adapte au mode sombre)
    static let secondaryText = Color(.secondaryLabel)
    
    /// Texte tertiaire (s'adapte au mode sombre)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - Couleurs de Bordure
    
    /// Bordure principale
    static let border = Color(.separator)
    
    /// Bordure secondaire
    static let secondaryBorder = Color(.opaqueSeparator)
}

// MARK: - Extensions pour contraste élevé

extension AppColors {
    /// Retourne une couleur avec contraste élevé si l'accessibilité est activée
    static func highContrast(_ color: Color) -> Color {
        // iOS gère automatiquement le contraste élevé via les couleurs système
        // Cette fonction peut être étendue pour des ajustements personnalisés
        return color
    }
}

