//
//  PaymentMethodsView.swift
//  Tshiakani VTC
//
//  Écran de gestion des méthodes de paiement (simplifié)
//

import SwiftUI

struct PaymentMethodsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var paymentViewModel = PaymentViewModel()
    @State private var showingContextMenu = false
    @State private var pendingMethod: PaymentMethod?
    
    // Couleur orange de la marque
    private let orangeColor = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    private var selectedMethod: PaymentMethod {
        paymentViewModel.selectedPaymentMethod ?? .cash
    }
    
    var body: some View {
        List {
            methodsSection
            infoSection
        }
        .navigationTitle("Moyens de paiement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await paymentViewModel.loadPaymentMethods()
            }
            paymentViewModel.loadDefaultPaymentMethod()
        }
        .onChange(of: paymentViewModel.selectedPaymentMethod) { _, newMethod in
            if let method = newMethod {
                Task {
                    await paymentViewModel.setDefaultPaymentMethod(method)
                }
            }
        }
        .confirmationDialog(
            pendingMethod?.displayName ?? "Méthode de paiement",
            isPresented: $showingContextMenu,
            titleVisibility: .visible
        ) {
            Button("Confirmer") {
                if let method = pendingMethod {
                    Task {
                        await paymentViewModel.setDefaultPaymentMethod(method)
                    }
                }
                pendingMethod = nil
            }
            Button("Annuler", role: .cancel) {
                pendingMethod = nil
            }
        } message: {
            Text("L'intégration API sera disponible prochainement. Souhaitez-vous continuer ?")
        }
    }
    
    // MARK: - Subviews
    
    private var methodsSection: some View {
        Section {
            ForEach(paymentViewModel.paymentMethods, id: \.self) { method in
                PaymentMethodRowView(
                    method: method,
                    isSelected: selectedMethod == method,
                    orangeColor: orangeColor
                ) {
                    if method.requiresContextMenu {
                        // Afficher le menu contextuel pour Orange Money et M-Pesa
                        pendingMethod = method
                        showingContextMenu = true
                    } else {
                        // Sélectionner directement pour les autres méthodes
                        Task {
                            await paymentViewModel.setDefaultPaymentMethod(method)
                        }
                    }
                }
            }
        }
    }
    
    private var infoSection: some View {
        Section {
            if let errorMessage = paymentViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("La méthode de paiement par défaut sera utilisée pour vos prochaines courses.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if paymentViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Payment Method Row View

struct PaymentMethodRowView: View {
    let method: PaymentMethod
    let isSelected: Bool
    let orangeColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(AppDesign.animationSnappy) {
                onSelect()
            }
        }) {
            HStack(spacing: AppDesign.spacingM) {
                iconView
                nameView
                Spacer()
                selectionIndicator
            }
            .padding(.vertical, AppDesign.spacingS)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AppDesign.animationSnappy, value: isSelected)
    }
    
    // MARK: - Row Subviews
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [method.color.opacity(0.2), method.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [AppColors.secondaryBackground.opacity(0.5), AppColors.secondaryBackground.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            
            Image(systemName: method.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isSelected ? method.color : AppColors.secondaryText)
        }
        .shadow(color: isSelected ? method.color.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
    }
    
    private var nameView: some View {
        Text(method.displayName)
            .font(AppTypography.body(weight: .medium))
            .foregroundColor(AppColors.primaryText)
    }
    
    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            ZStack {
                Circle()
                    .fill(method.color)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: method.color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PaymentMethodsView()
            .environmentObject(AuthViewModel())
    }
}
