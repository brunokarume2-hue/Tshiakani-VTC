//
//  PrivacyPolicyView.swift
//  Tshiakani VTC
//
//  Écran Politique de confidentialité
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // En-tête
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Politique de confidentialité")
                            .font(AppTypography.largeTitle())
                            .foregroundColor(AppColors.primaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        
                        Text("Dernière mise à jour : 8 novembre 2025")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    .padding(.bottom, 8)
                    
                    // Introduction
                    section(
                        title: "Introduction",
                        content: "Tshiakani VTC s'engage à protéger votre vie privée. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations personnelles."
                    )
                    
                    // Collecte d'informations
                    section(
                        title: "Collecte d'informations",
                        content: "Nous collectons les informations que vous nous fournissez lors de l'inscription et de l'utilisation de l'application, notamment votre nom, numéro de téléphone et localisation. Nous collectons également des informations sur votre utilisation de l'application pour améliorer nos services."
                    )
                    
                    // Utilisation des informations
                    section(
                        title: "Utilisation des informations",
                        content: "Nous utilisons vos informations pour fournir, améliorer et personnaliser nos services, traiter vos commandes et communiquer avec vous. Nous ne vendons jamais vos informations personnelles à des tiers."
                    )
                    
                    // Protection des données
                    section(
                        title: "Protection des données",
                        content: "Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos informations personnelles contre tout accès non autorisé, modification, divulgation ou destruction. Toutes les données sont chiffrées et stockées de manière sécurisée."
                    )
                    
                    // Partage des données
                    section(
                        title: "Partage des données",
                        content: "Nous ne partageons vos informations qu'avec les conducteurs nécessaires pour fournir le service de transport. Nous pouvons également partager des informations si la loi l'exige ou pour protéger nos droits légaux."
                    )
                    
                    // Vos droits
                    section(
                        title: "Vos droits",
                        content: "Vous avez le droit d'accéder, de modifier ou de supprimer vos informations personnelles à tout moment. Vous pouvez également vous opposer au traitement de vos données ou demander une copie de vos informations."
                    )
                    
                    // Contact
                    section(
                        title: "Contact",
                        content: "Pour toute question concernant cette politique de confidentialité, contactez-nous à support@tshiakanivtc.com"
                    )
                }
                .padding()
            }
            .navigationTitle("Politique de confidentialité")
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
    PrivacyPolicyView()
}

