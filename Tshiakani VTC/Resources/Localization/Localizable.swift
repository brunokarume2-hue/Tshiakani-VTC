//
//  Localizable.swift
//  Tshiakani VTC
//
//  Système de localisation pour français, anglais et lingala
//

import Foundation

/// Gestionnaire de localisation avec support multi-langues
class Localizable {
    static let shared = Localizable()
    
    private var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }
    
    var currentLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "app_language") ?? 
            Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "fr"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "app_language")
        }
    }
    
    func string(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// MARK: - Extension String pour localisation facile

extension String {
    var localized: String {
        return Localizable.shared.string(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: Localizable.shared.string(for: self), arguments: arguments)
    }
}

