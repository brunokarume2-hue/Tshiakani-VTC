//
//  SavedAddress.swift
//  Tshiakani VTC
//
//  Model pour les adresses sauvegardées
//

import Foundation

struct SavedAddress: Identifiable, Codable {
    let id: String
    var name: String
    var address: String
    var location: Location
    var icon: String?
    var isFavorite: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         address: String,
         location: Location,
         icon: String? = nil,
         isFavorite: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.icon = icon
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

