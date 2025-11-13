//
//  ChatMessage.swift
//  Tshiakani VTC
//
//  Model pour les messages de chat
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let message: String
    let senderId: String
    let senderName: String
    let timestamp: Date
    let isFromDriver: Bool
}

