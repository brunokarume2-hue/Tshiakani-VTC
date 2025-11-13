//
//  RatingView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct RatingView: View {
    let driverName: String
    let driverPhoto: String? // URL ou nom de l'image
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @Environment(\.dismiss) var dismiss
    let onSend: (Int, String) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Photo de profil du conducteur
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentOrange.opacity(0.3), AppColors.accentOrangeLight.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                if let photo = driverPhoto, !photo.isEmpty {
                    // Ici, vous pourriez charger une vraie image
                    Text(driverName.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppColors.accentOrange)
                } else {
                    Text(driverName.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppColors.accentOrange)
                }
            }
            
            // Question
            Text("Comment s'est passée votre course avec \(driverName) ?")
                .font(.headline)
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Étoiles de notation
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            rating = star
                        }
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(star <= rating ? AppColors.accentOrange : AppColors.secondaryText.opacity(0.3))
                            .overlay(
                                Circle()
                                    .stroke(star <= rating ? AppColors.accentOrange : AppColors.secondaryText.opacity(0.3), lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            )
                    }
                }
            }
            
            // Zone de commentaire
            TextEditor(text: $comment)
                .frame(height: 120)
                .padding(8)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if comment.isEmpty {
                            Text("Laissez un commentaire...")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.leading, 4)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .padding(.horizontal)
            
            // Bouton Envoyer
            Button(action: {
                onSend(rating, comment)
                dismiss()
            }) {
                Text("Envoyer")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppColors.accentOrange, AppColors.accentOrange.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .disabled(rating == 0)
            .opacity(rating == 0 ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding()
        .background(AppColors.accentOrangeVeryLight)
    }
}

#Preview {
    RatingView(
        driverName: "Jean",
        driverPhoto: nil,
        onSend: { rating, comment in
            print("Rating: \(rating), Comment: \(comment)")
        }
    )
}

