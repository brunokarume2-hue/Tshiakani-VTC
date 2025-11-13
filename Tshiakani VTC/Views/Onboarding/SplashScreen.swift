//
//  SplashScreen.swift
//  Tshiakani VTC
//
//  Écran de démarrage simplifié avec illustration cartoon
//

import SwiftUI

struct SplashScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    // Couleur orange de la marque
    private let orangeColor = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    var body: some View {
        ZStack {
            // Fond blanc simple
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Illustration cartoon de voiture
                CartoonCarView(orangeColor: orangeColor)
                    .frame(width: 200, height: 150)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Nom de l'application
                Text("Tshiakani VTC")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(orangeColor)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Animation simple d'apparition
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Illustration Cartoon de Voiture

struct CartoonCarView: View {
    let orangeColor: Color
    
    var body: some View {
        ZStack {
            // Roues (en arrière-plan)
            HStack(spacing: 110) {
                // Roue avant
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 45, height: 45)
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 28, height: 28)
                }
                .offset(x: -50, y: 30)
                
                // Roue arrière
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 45, height: 45)
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 28, height: 28)
                }
                .offset(x: 50, y: 30)
            }
            
            // Corps principal de la voiture
            RoundedRectangle(cornerRadius: 25)
                .fill(orangeColor)
                .frame(width: 200, height: 90)
                .shadow(color: orangeColor.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Toit de la voiture
            RoundedRectangle(cornerRadius: 18)
                .fill(orangeColor.opacity(0.85))
                .frame(width: 110, height: 55)
                .offset(y: -30)
            
            // Fenêtres
            HStack(spacing: 35) {
                // Fenêtre avant
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 38, height: 32)
                    .offset(x: -28, y: -30)
                
                // Fenêtre arrière
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 38, height: 32)
                    .offset(x: 28, y: -30)
            }
            
            // Phares (yeux souriants)
            HStack(spacing: 90) {
                // Phare avant gauche
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.yellow.opacity(0.5), radius: 5)
                }
                .offset(x: -48, y: -10)
                
                // Phare avant droit
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.yellow.opacity(0.5), radius: 5)
                }
                .offset(x: 48, y: -10)
            }
            
            // Sourire (pare-chocs)
            Path { path in
                path.move(to: CGPoint(x: 70, y: 35))
                path.addQuadCurve(
                    to: CGPoint(x: 130, y: 35),
                    control: CGPoint(x: 100, y: 42)
                )
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 3)
        }
        .frame(width: 200, height: 150)
    }
}

#Preview {
    SplashScreen()
}

