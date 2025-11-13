//
//  StringExtensions.swift
//  Tshiakani VTC
//
//  Extensions pour masquage des données sensibles
//

import Foundation

extension String {
    /// Masque un numéro de téléphone (ex: +243 820098808 → +243 *** *** 808)
    func maskedPhoneNumber() -> String {
        // Nettoyer le numéro
        let cleaned = self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Extraire l'indicatif (premiers chiffres jusqu'à +)
        if let plusIndex = cleaned.firstIndex(of: "+") {
            let afterPlus = cleaned.index(after: plusIndex)
            let countryCodeEnd = cleaned.index(afterPlus, offsetBy: min(3, cleaned.distance(from: afterPlus, to: cleaned.endIndex)))
            let countryCode = String(cleaned[plusIndex..<countryCodeEnd])
            let number = String(cleaned[countryCodeEnd...])
            
            // Masquer le milieu, garder les 3 derniers chiffres
            if number.count >= 3 {
                let lastThree = String(number.suffix(3))
                let maskedMiddle = String(repeating: "*", count: max(0, number.count - 3))
                return "\(countryCode) \(maskedMiddle.chunkedString(into: 3).joined(separator: " ")) \(lastThree)"
            }
            return countryCode + " " + String(repeating: "*", count: number.count)
        }
        
        // Si pas d'indicatif, masquer tout sauf les 3 derniers
        if self.count >= 3 {
            let lastThree = String(self.suffix(3))
            let masked = String(repeating: "*", count: max(0, self.count - 3))
            return masked + " " + lastThree
        }
        
        return String(repeating: "*", count: self.count)
    }
    
    /// Chunk une string en groupes de n caractères
    private func chunkedString(into size: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let nextIndex = index(currentIndex, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }
        
        return chunks
    }
    
    /// Valide un numéro de téléphone congolais (9 chiffres après +243)
    func isValidCongolesePhoneNumber() -> Bool {
        let cleaned = self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Vérifier le format +243XXXXXXXXX (12 caractères) ou XXXXXXXXX (9 chiffres)
        if cleaned.hasPrefix("+243") {
            let number = String(cleaned.dropFirst(4))
            return number.count == 9 && number.allSatisfy { $0.isNumber }
        } else {
            return cleaned.count == 9 && cleaned.allSatisfy { $0.isNumber }
        }
    }
    
    /// Valide un code de vérification à 6 chiffres
    func isValidVerificationCode() -> Bool {
        return self.count == 6 && self.allSatisfy { $0.isNumber }
    }
}

