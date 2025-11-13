//
//  StatusBadge.swift
//  Tshiakani VTC
//
//  Badge pour afficher le statut d'une course
//

import SwiftUI

struct StatusBadge: View {
    let status: RideStatus
    
    var body: some View {
        Text(statusLabel)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }
    
    private var statusLabel: String {
        switch status {
        case .pending:
            return "En attente"
        case .accepted:
            return "Accepté"
        case .driverArriving:
            return "En route"
        case .inProgress:
            return "En cours"
        case .completed:
            return "Terminé"
        case .cancelled:
            return "Annulé"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return Color.yellow.opacity(0.2)
        case .accepted:
            return Color.blue.opacity(0.2)
        case .driverArriving:
            return Color.blue.opacity(0.2)
        case .inProgress:
            return Color.green.opacity(0.2)
        case .completed:
            return Color.gray.opacity(0.2)
        case .cancelled:
            return Color.red.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .blue
        case .driverArriving:
            return .blue
        case .inProgress:
            return .green
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadge(status: .pending)
        StatusBadge(status: .accepted)
        StatusBadge(status: .driverArriving)
        StatusBadge(status: .inProgress)
        StatusBadge(status: .completed)
        StatusBadge(status: .cancelled)
    }
    .padding()
}

