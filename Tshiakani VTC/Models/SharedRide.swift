//
//  SharedRide.swift
//  Tshiakani VTC
//
//  Model pour les courses partagées
//

import Foundation

struct SharedRide: Identifiable, Codable {
    let id: String
    let rideId: String
    let sharedWith: [String] // Contact IDs
    let shareLink: String
    let createdAt: Date
    let expiresAt: Date?
}

