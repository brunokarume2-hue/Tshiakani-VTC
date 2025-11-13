//
//  Payment.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
}

struct Payment: Identifiable, Codable {
    let id: String
    var rideId: String
    var userId: String
    var amount: Double
    var method: PaymentMethod
    var status: PaymentStatus
    var transactionId: String?
    var mobileMoneyNumber: String? // Pour Mobile Money
    var createdAt: Date
    var completedAt: Date?
    
    init(id: String = UUID().uuidString,
         rideId: String,
         userId: String,
         amount: Double,
         method: PaymentMethod,
         status: PaymentStatus = .pending,
         transactionId: String? = nil,
         mobileMoneyNumber: String? = nil,
         createdAt: Date = Date(),
         completedAt: Date? = nil) {
        self.id = id
        self.rideId = rideId
        self.userId = userId
        self.amount = amount
        self.method = method
        self.status = status
        self.transactionId = transactionId
        self.mobileMoneyNumber = mobileMoneyNumber
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

