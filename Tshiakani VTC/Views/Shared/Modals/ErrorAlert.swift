//
//  ErrorAlert.swift
//  Tshiakani VTC
//
//  Alerte d'erreur réutilisable
//

import SwiftUI

struct ErrorAlert: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("OK") {
                    action?()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        action: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ErrorAlert(
            isPresented: isPresented,
            title: title,
            message: message,
            action: action
        ))
    }
}

