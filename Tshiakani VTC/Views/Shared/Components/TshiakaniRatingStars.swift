//
//  TshiakaniRatingStars.swift
//  Tshiakani VTC
//
//  Composant d'évaluation par étoiles avec animation fluide
//

import SwiftUI

struct TshiakaniRatingStars: View {
    @Binding var rating: Int
    let maxRating: Int
    let starSize: CGFloat
    let isEditable: Bool
    
    @State private var hoveredRating: Int = 0
    
    init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        starSize: CGFloat = 32,
        isEditable: Bool = true
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.isEditable = isEditable
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { index in
                starView(for: index)
                    .onTapGesture {
                        if isEditable {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                rating = index
                            }
                        }
                    }
            }
        }
    }
    
    private func starView(for index: Int) -> some View {
        Image(systemName: starName(for: index))
            .font(.system(size: starSize))
            .foregroundColor(starColor(for: index))
            .scaleEffect(index == rating ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
    }
    
    private func starName(for index: Int) -> String {
        let displayRating = hoveredRating > 0 ? hoveredRating : rating
        return index <= displayRating ? "star.fill" : "star"
    }
    
    private func starColor(for index: Int) -> Color {
        let displayRating = hoveredRating > 0 ? hoveredRating : rating
        return index <= displayRating ? AppColors.accentOrange : AppColors.secondaryText.opacity(0.3)
    }
}

#Preview {
    VStack(spacing: 40) {
        TshiakaniRatingStars(rating: .constant(4))
        
        TshiakaniRatingStars(
            rating: .constant(5),
            starSize: 40
        )
        
        TshiakaniRatingStars(
            rating: .constant(3),
            isEditable: false
        )
    }
    .padding()
}

