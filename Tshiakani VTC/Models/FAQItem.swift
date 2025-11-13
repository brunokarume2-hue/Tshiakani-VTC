//
//  FAQItem.swift
//  Tshiakani VTC
//
//  Model pour les éléments de FAQ
//

import Foundation

struct FAQItem: Identifiable, Codable {
    let id: String
    let question: String
    let answer: String
    
    // Initializer pour créer depuis les données API
    init(id: String, question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

