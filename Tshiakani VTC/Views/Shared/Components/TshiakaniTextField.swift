//
//  TshiakaniTextField.swift
//  Tshiakani VTC
//
//  Champ de texte réutilisable avec validation et accessibilité
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

struct TshiakaniTextField: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    
    #if os(iOS)
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    #else
    // Types de remplacement pour les plateformes non-iOS
    var keyboardType: Int = 0
    var textContentType: String? = nil
    #endif
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var icon: String? = nil
    var onCommit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.primaryText)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTypography.body())
                        .foregroundColor(isFocused ? AppColors.primaryBlue : AppColors.secondaryText)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                            TextField(placeholder, text: $text)
                        }
                }
                .font(AppTypography.body())
                #if os(iOS)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                #endif
                .focused($isFocused)
                .onSubmit {
                    onCommit?()
                }
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .padding(AppDesign.spacingM)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(
                        isFocused ? AppColors.primaryBlue : (errorMessage != nil ? AppColors.error : AppColors.border),
                        lineWidth: isFocused || errorMessage != nil ? 2 : 1
                    )
            )
            .animation(AppDesign.animationFast, value: isFocused)
            .animation(AppDesign.animationFast, value: errorMessage != nil)
            
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.error)
                    
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.error)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var phoneText = ""
        @State private var codeText = ""
        @State private var passwordText = ""
        
        var body: some View {
            VStack(spacing: 20) {
                #if os(iOS)
                TshiakaniTextField(
                    title: "Numéro de téléphone",
                    placeholder: "820 098 808",
                    text: $phoneText,
                    keyboardType: .phonePad,
                    icon: "phone.fill"
                )
                
                TshiakaniTextField(
                    title: "Code de vérification",
                    placeholder: "123456",
                    text: $codeText,
                    keyboardType: .numberPad,
                    errorMessage: "Code invalide"
                )
                #else
                TshiakaniTextField(
                    title: "Numéro de téléphone",
                    placeholder: "820 098 808",
                    text: $phoneText,
                    icon: "phone.fill"
                )
                
                TshiakaniTextField(
                    title: "Code de vérification",
                    placeholder: "123456",
                    text: $codeText,
                    errorMessage: "Code invalide"
                )
                #endif
                
                TshiakaniTextField(
                    title: nil,
                    placeholder: "Mot de passe",
                    text: $passwordText,
                    isSecure: true,
                    icon: "lock.fill"
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

