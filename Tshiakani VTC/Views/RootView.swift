//
//  RootView.swift
//  Tshiakani VTC
//
//  Point d'entrée principal qui gère la redirection selon l'état d'authentification
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    // OPTIMISATION: Ne pas créer LocationManager et AuthViewModel au démarrage
    // Ils seront créés seulement quand nécessaire dans les vues enfants
    @State private var showSplash = true
    
    @ViewBuilder
    var body: some View {
        Group {
            // 0. Afficher le splash screen au démarrage (première fois seulement)
            if showSplash && !authManager.hasSeenOnboarding {
                SplashScreen()
                    .onAppear {
                        // OPTIMISATION: Réduire le temps du splash (0.8s au lieu de 1.5s)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showSplash = false
                        }
                    }
            }
            // 1. Vérifier si l'onboarding a été vu
            else if !authManager.hasSeenOnboarding {
                OnboardingView()
                    .environmentObject(authManager)
            }
            // 2. Vérifier si l'utilisateur est authentifié
            else if !authManager.isAuthenticated {
                AuthGateView()
                    .environmentObject(authManager)
            }
            // 3. Rediriger selon le rôle
            else {
                if authManager.userRole == .client {
                    // OPTIMISATION: Créer AuthViewModel et LocationManager seulement quand nécessaire
                    ClientMainView()
                        .environmentObject(AuthViewModel()) // Créé seulement quand nécessaire
                        .environmentObject(authManager)
                        .environmentObject(LocationManager.shared) // Utiliser le singleton
                        .onAppear {
                            // Démarrer le suivi de localisation pour le client (non-bloquant)
                            LocationManager.shared.requestAuthorizationIfNeeded()
                            print("✅ RootView: ClientMainView affiché")
                        }
                } else if authManager.userRole == .admin {
                    // Rôle admin
                    AdminDashboardView()
                        .environmentObject(authManager)
                } else {
                    // Rôle driver : Les drivers ont leur propre application séparée
                    // Afficher un message d'information
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Application Conducteur")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Les conducteurs utilisent une application séparée.\nVeuillez utiliser l'application dédiée aux conducteurs.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Déconnexion") {
                            authManager.signOut()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: [])
        // OPTIMISATION: Réduire les logs pour améliorer les performances
        // Les onChange sont gérés automatiquement par SwiftUI
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
}

