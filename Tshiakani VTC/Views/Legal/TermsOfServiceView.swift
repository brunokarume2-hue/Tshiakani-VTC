//
//  TermsOfServiceView.swift
//  Tshiakani VTC
//
//  Écran Conditions d'utilisation
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // En-tête
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conditions d'utilisation")
                            .font(AppTypography.largeTitle())
                            .foregroundColor(AppColors.primaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text("Dernière mise à jour : 8 novembre 2025")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    .padding(.bottom, 8)
                    
                    // Sections
                    section(
                        title: "1. Acceptation des conditions",
                        content: "En utilisant l'application Tshiakani VTC, vous acceptez d'être lié par ces conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre service."
                    )
                    
                    section(
                        title: "2. Description du service",
                        content: "Tshiakani VTC est une plateforme de mise en relation entre clients et conducteurs de moto-taxis à Kinshasa. Nous facilitons la réservation et le paiement de courses, mais ne sommes pas responsables des services de transport fournis par les conducteurs."
                    )
                    
                    section(
                        title: "3. Utilisation du service",
                        content: "Vous vous engagez à utiliser le service de manière légale et responsable. Il est interdit d'utiliser le service à des fins frauduleuses ou illégales."
                    )
                    
                    section(
                        title: "4. Compte utilisateur",
                        content: "Vous êtes responsable de maintenir la confidentialité de vos informations de compte. Vous devez nous informer immédiatement de toute utilisation non autorisée."
                    )
                    
                    section(
                        title: "5. Paiements",
                        content: "Les paiements sont traités de manière sécurisée. Les prix peuvent varier en fonction de la distance, de la demande et d'autres facteurs. Tous les prix sont en CDF (Franc congolais)."
                    )
                    
                    section(
                        title: "6. Annulations et remboursements",
                        content: "Les politiques d'annulation et de remboursement sont définies dans les conditions spécifiques de chaque course. Veuillez consulter les détails avant de confirmer une réservation."
                    )
                    
                    section(
                        title: "7. Responsabilité",
                        content: "Tshiakani VTC agit en tant qu'intermédiaire. Nous ne sommes pas responsables des accidents, des retards ou des dommages causés par les conducteurs."
                    )
                    
                    section(
                        title: "8. Propriété intellectuelle",
                        content: "Tous les contenus de l'application, y compris les logos, textes et designs, sont la propriété de Tshiakani VTC et sont protégés par les lois sur la propriété intellectuelle."
                    )
                    
                    section(
                        title: "9. Modifications des conditions",
                        content: "Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications seront communiquées via l'application."
                    )
                    
                    section(
                        title: "10. Contact",
                        content: "Pour toute question concernant ces conditions, contactez-nous à support@tshiakanivtc.com"
                    )
                }
                .padding()
            }
            .navigationTitle("Conditions d'utilisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("common.button.close".localized)
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
            }
            .background(AppColors.background)
        }
    }
    
    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTypography.headline())
                .foregroundColor(AppColors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            Text(content)
                .font(AppTypography.body())
                .foregroundColor(AppColors.secondaryText)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TermsOfServiceView()
}

