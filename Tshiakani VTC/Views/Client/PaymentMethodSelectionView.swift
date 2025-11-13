//
//  PaymentMethodSelectionView.swift
//  Tshiakani VTC
//
//  Vue pour sélectionner la méthode de paiement
//

import SwiftUI

struct PaymentMethodSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMethod: PaymentMethod
    let estimatedPrice: Double
    
    @State private var showingContextMenu = false
    @State private var pendingMethod: PaymentMethod?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Méthode de paiement") {
                    ForEach(PaymentMethod.availableMethods, id: \.self) { method in
                        Button(action: {
                            if method.requiresContextMenu {
                                // Afficher le menu contextuel pour Orange Money et M-Pesa
                                pendingMethod = method
                                showingContextMenu = true
                            } else {
                                // Sélectionner directement pour les autres méthodes
                                selectedMethod = method
                            }
                        }) {
                            HStack(spacing: AppDesign.spacingM) {
                                Image(systemName: method.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedMethod == method ? method.color : AppColors.secondaryText)
                                    .frame(width: 30)
                                
                                Text(method.displayName)
                                    .font(AppTypography.body())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Spacer()
                                
                                if selectedMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(method.color)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Montant estimé")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(estimatedPrice))-\(Int(estimatedPrice * 1.1)) CDF")
                            .font(AppTypography.body(weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Méthode de paiement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmer") {
                        dismiss()
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
                        selectedMethod = method
                        // TODO: Ici sera ajouté l'appel API pour initier le paiement
                        // Exemple: await initiateMobileMoneyPayment(method: method)
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
    }
}

#Preview {
    PaymentMethodSelectionView(
        selectedMethod: .constant(.cash),
        estimatedPrice: 18000
    )
}

