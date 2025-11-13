//
//  ModernComponents.swift
//  Tshiakani VTC
//
//  Composants modernes réutilisables selon les Apple Design Tips
//

import SwiftUI

// MARK: - Modern Card Component

struct ModernCard<Content: View>: View {
    let content: Content
    let material: Material
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        material: Material = .regularMaterial,
        cornerRadius: CGFloat = AppDesign.cornerRadiusL,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppDesign.spacingM)
            .background(material)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
    }
}

// MARK: - Modern Button Component

struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }
    
    var body: some View {
        Button(action: {
            switch style {
            case .primary:
                HapticFeedback.medium()
            case .secondary, .outline:
                HapticFeedback.light()
            }
            action()
        }) {
            HStack(spacing: AppDesign.spacingS) {
                if isLoading {
                    ModernLoadingView()
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .cornerRadius(AppDesign.cornerRadiusL)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusL)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        }
        .buttonStyle(EnhancedButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(AppDesign.animationFast, value: isLoading)
        .animation(AppDesign.animationFast, value: isDisabled)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.clear
                .background(.thinMaterial)
        case .outline:
            Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .outline:
            return AppColors.primaryText
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return AppColors.accentOrange
        case .secondary:
            return AppColors.border
        case .primary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outline:
            return 2
        case .secondary:
            return 1
        case .primary:
            return 0
        }
    }
    
    private var shadowColor: Color {
        style == .primary ? .black.opacity(0.2) : .clear
    }
    
    private var shadowRadius: CGFloat {
        style == .primary ? 8 : 0
    }
    
    private var shadowY: CGFloat {
        style == .primary ? 4 : 0
    }
}

// MARK: - Modern Text Field

struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
            if !title.isEmpty {
                Text(title)
                    .font(AppTypography.subheadline(weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            HStack(spacing: AppDesign.spacingS) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isFocused ? AppColors.accentOrange : AppColors.secondaryText)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(AppTypography.body())
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(AppTypography.body())
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                }
            }
            .padding(AppDesign.spacingM)
            .background(.thinMaterial)
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(isFocused ? AppColors.accentOrange : AppColors.border, lineWidth: isFocused ? 2 : 1)
            )
            .animation(AppDesign.animationFast, value: isFocused)
        }
    }
}

// MARK: - Modern Icon Button

struct ModernIconButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    var size: CGFloat = 44
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(color)
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(EnhancedButtonStyle())
    }
}

// MARK: - Modern Badge

struct ModernBadge: View {
    let text: String
    let color: Color
    let style: BadgeStyle
    
    enum BadgeStyle {
        case filled
        case outline
    }
    
    var body: some View {
        Text(text)
            .font(AppTypography.caption(weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, AppDesign.spacingS)
            .padding(.vertical, AppDesign.spacingXS)
            .background(backgroundColor)
            .cornerRadius(AppDesign.cornerRadiusS)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var textColor: Color {
        switch style {
        case .filled:
            return .white
        case .outline:
            return color
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return color
        case .outline:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outline:
            return color
        }
    }
    
    private var borderWidth: CGFloat {
        style == .outline ? 1.5 : 0
    }
}

// MARK: - Modern Divider

struct ModernDivider: View {
    let color: Color
    let thickness: CGFloat
    
    init(color: Color = AppColors.border, thickness: CGFloat = 1) {
        self.color = color
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.3))
            .frame(height: thickness)
            .padding(.horizontal, AppDesign.spacingM)
    }
}

#Preview {
    VStack(spacing: AppDesign.spacingL) {
        ModernCard {
            Text("Carte moderne avec matériau")
        }
        
        ModernButton(title: "Bouton Principal", icon: "checkmark", style: .primary) {
            print("Action")
        }
        
        ModernButton(title: "Bouton Secondaire", style: .secondary) {
            print("Action")
        }
        
        ModernTextField(title: "Email", placeholder: "Entrez votre email", text: .constant(""), icon: "envelope")
        
        ModernIconButton(icon: "heart.fill", color: AppColors.accentOrange) {
            print("Action")
        }
        
        HStack {
            ModernBadge(text: "Nouveau", color: AppColors.success, style: .filled)
            ModernBadge(text: "Pro", color: AppColors.accentOrange, style: .outline)
        }
    }
    .padding()
}

