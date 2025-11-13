//
//  SupportMessage.swift
//  Tshiakani VTC
//
//  Model pour les messages de support
//

import Foundation

struct SupportMessage: Identifiable, Codable {
    let id: String
    let message: String
    let isFromUser: Bool
    let timestamp: Date
    
    // Initializer pour créer depuis les données API
    init(id: String, message: String, isFromUser: Bool, timestamp: Date) {
        self.id = id
        self.message = message
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}
