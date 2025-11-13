//
//  AlertExtensions.swift
//  Tshiakani VTC
//
//  Système d'alertes natives réutilisables
//

import SwiftUI
import Combine

// MARK: - Alert Manager

@MainActor
class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var alert: TshiakaniAlert? = nil
    
    func show(_ alert: TshiakaniAlert) {
        self.alert = alert
    }
    
    func dismiss() {
        self.alert = nil
    }
}

// MARK: - Alert Types

struct TshiakaniAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let style: AlertStyle
    let actions: [AlertAction]
    
    enum AlertStyle {
        case error
        case warning
        case success
        case info
    }
    
    struct AlertAction {
        let title: String
        let style: ActionStyle
        let action: (() -> Void)?
        
        enum ActionStyle {
            case `default`
            case cancel
            case destructive
        }
    }
}

// MARK: - Alert View Modifier

struct TshiakaniAlertModifier: ViewModifier {
    @StateObject private var alertManager = AlertManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                alertManager.alert?.title ?? "",
                isPresented: Binding(
                    get: { alertManager.alert != nil },
                    set: { if !$0 { alertManager.dismiss() } }
                ),
                presenting: alertManager.alert
            ) { alert in
                ForEach(alert.actions, id: \.title) { action in
                    Button(action.title, role: buttonRole(for: action.style)) {
                        action.action?()
                    }
                }
            } message: { alert in
                Text(alert.message)
            }
    }
    
    private func buttonRole(for style: TshiakaniAlert.AlertAction.ActionStyle) -> ButtonRole? {
        switch style {
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        case .default:
            return nil
        }
    }
}

extension View {
    func tshiakaniAlert() -> some View {
        self.modifier(TshiakaniAlertModifier())
    }
}

// MARK: - Convenience Functions

extension AlertManager {
    func showError(title: String, message: String, action: (() -> Void)? = nil) {
        show(TshiakaniAlert(
            title: title,
            message: message,
            style: .error,
            actions: [
                TshiakaniAlert.AlertAction(
                    title: "OK",
                    style: .default,
                    action: action
                )
            ]
        ))
    }
    
    func showSuccess(title: String, message: String, action: (() -> Void)? = nil) {
        show(TshiakaniAlert(
            title: title,
            message: message,
            style: .success,
            actions: [
                TshiakaniAlert.AlertAction(
                    title: "OK",
                    style: .default,
                    action: action
                )
            ]
        ))
    }
    
    func showConfirmation(
        title: String,
        message: String,
        confirmTitle: String = "Confirmer",
        cancelTitle: String = "Annuler",
        onConfirm: @escaping () -> Void
    ) {
        show(TshiakaniAlert(
            title: title,
            message: message,
            style: .info,
            actions: [
                TshiakaniAlert.AlertAction(
                    title: cancelTitle,
                    style: .cancel,
                    action: nil
                ),
                TshiakaniAlert.AlertAction(
                    title: confirmTitle,
                    style: .`default`,
                    action: onConfirm
                )
            ]
        ))
    }
}

