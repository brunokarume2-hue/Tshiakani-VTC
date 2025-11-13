//
//  HelpView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct HelpView: View {
    @StateObject private var supportViewModel = SupportViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // FAQ
                VStack(alignment: .leading, spacing: AppDesign.spacingM) {
                    HStack(spacing: AppDesign.spacingS) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.accentOrange)
                        
                        Text("Questions fréquentes")
                            .font(AppTypography.title2(weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    
                    ForEach(supportViewModel.faqItems) { item in
                        FAQItemView(
                            question: item.question,
                            answer: item.answer,
                            isExpanded: supportViewModel.expandedFAQItem == item.id,
                            onToggle: {
                                supportViewModel.toggleFAQItem(item.id)
                            }
                        )
                    }
                }
                .padding(AppDesign.spacingM)
                .background(.thinMaterial)
                .cornerRadius(AppDesign.cornerRadiusL)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Contact
                VStack(alignment: .leading, spacing: AppDesign.spacingM) {
                    HStack(spacing: AppDesign.spacingS) {
                        Image(systemName: "headphones.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.accentOrange)
                        
                        Text("Besoin d'aide ?")
                            .font(AppTypography.title2(weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    
                    NavigationLink {
                        ClientSupportView()
                    } label: {
                        HStack(spacing: AppDesign.spacingS) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Contacter le support")
                                .font(AppTypography.headline(weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppColors.success, AppColors.success.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(EnhancedButtonStyle())
                    .accessibilityLabel("Contacter le support")
                    .accessibilityHint("Envoyer un message au service client")
                    
                    Button(action: {
                        HapticFeedback.medium()
                        if let url = URL(string: "tel://+243900000000") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: AppDesign.spacingS) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Appeler le support")
                                .font(AppTypography.headline(weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppColors.accentOrange, AppColors.accentOrange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AppDesign.cornerRadiusL)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(EnhancedButtonStyle())
                    .accessibilityLabel("Appeler le support")
                    .accessibilityHint("Appeler le service client")
                }
                .padding(AppDesign.spacingM)
                .background(.thinMaterial)
                .cornerRadius(AppDesign.cornerRadiusL)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(AppDesign.spacingM)
        }
        .background(AppColors.background)
        .navigationTitle("Aide")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            supportViewModel.loadFAQ()
        }
    }
}

struct FAQItemView: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                HapticFeedback.light()
                withAnimation(AppDesign.animationSnappy) {
                    onToggle()
                }
            }) {
                HStack(spacing: AppDesign.spacingS) {
                    Text(question)
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accentOrange)
                }
                .padding(.vertical, AppDesign.spacingXS)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(AppTypography.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.top, AppDesign.spacingXS)
            }
        }
        .padding(AppDesign.spacingS)
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}

