//
//  SupportTicket.swift
//  Tshiakani VTC
//
//  Model pour les tickets de support
//

import Foundation

struct SupportTicket: Identifiable, Codable {
    let id: String
    let subject: String
    let message: String
    let category: String
    let status: String
    let priority: String?
    let createdAt: Date
    let updatedAt: Date
    let resolvedAt: Date?
    
    // Initializer pour créer depuis les données API
    init(id: String,
         subject: String,
         message: String,
         category: String,
         status: String,
         priority: String? = nil,
         createdAt: Date,
         updatedAt: Date,
         resolvedAt: Date? = nil) {
        self.id = id
        self.subject = subject
        self.message = message
        self.category = category
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.resolvedAt = resolvedAt
    }
}

