//
//  NotificationsView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var notificationService = NotificationService.shared
    @State private var notifications: [NotificationItem] = []
    
    init() {
        // Initialiser avec un AuthViewModel temporaire, sera mis à jour via environmentObject
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        List {
            // Section Paramètres de notifications
            Section("Paramètres") {
                Toggle("Activer les notifications", isOn: Binding(
                    get: { settingsViewModel.notificationsEnabled },
                    set: { newValue in
                        Task {
                            await settingsViewModel.setNotificationsEnabled(newValue)
                        }
                    }
                ))
            }
            
            // Section Historique des notifications
            Section("Historique") {
                if notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Aucune notification")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        // Simuler des notifications (à remplacer par une vraie source de données)
        notifications = [
            NotificationItem(
                id: "1",
                title: "Course acceptée",
                message: "Votre course a été acceptée par un conducteur",
                type: .ride,
                date: Date().addingTimeInterval(-3600)
            ),
            NotificationItem(
                id: "2",
                title: "Promotion",
                message: "Réduction de 20% sur votre prochaine course",
                type: .promotion,
                date: Date().addingTimeInterval(-7200)
            ),
            NotificationItem(
                id: "3",
                title: "Sécurité",
                message: "N'oubliez pas de vérifier les informations du conducteur",
                type: .security,
                date: Date().addingTimeInterval(-86400)
            )
        ]
    }
}

struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let date: Date
}

enum NotificationType {
    case ride, promotion, security, system
}

struct NotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icône
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var iconName: String {
        switch notification.type {
        case .ride: return "car.fill"
        case .promotion: return "tag.fill"
        case .security: return "shield.fill"
        case .system: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .ride: return .green
        case .promotion: return .orange
        case .security: return .red
        case .system: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(AuthViewModel())
    }
}

