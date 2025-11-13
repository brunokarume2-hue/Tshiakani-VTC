//
//  PriceEstimate.swift
//  Tshiakani VTC
//
//  Modèle pour les estimations de prix avec IA
//

import Foundation

struct PriceEstimate: Codable {
    let price: Double
    let basePrice: Double
    let distance: Double
    let explanation: String
    let multipliers: PriceMultipliers
    let breakdown: PriceBreakdownData
}

struct PriceMultipliers: Codable {
    let time: Double
    let day: Double
    let surge: Double
}

struct PriceBreakdownData: Codable {
    let base: Double
    let distance: Double
    let timeAdjustment: Double
    let dayAdjustment: Double
    let surgeAdjustment: Double
}

