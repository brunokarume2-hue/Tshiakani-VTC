//
//  SideMenuView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    @State private var showingHistory = false
    @State private var showingNotifications = false
    @State private var showingSecurity = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingSupport = false
    @State private var showingCity = false
    @State private var showingDriverMode = false
    
    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Menu latéral
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // En-tête avec profil - Photo circulaire
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            // Photo de profil circulaire
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.accentOrange.opacity(0.2), AppColors.accentOrangeLight.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                
                                // Initiale ou icône
                                Text(authViewModel.currentUser?.name.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(authViewModel.currentUser?.name ?? "Utilisateur")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(authViewModel.currentUser?.phoneNumber ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    
                    // Options du menu
                    ScrollView {
                        VStack(spacing: 0) {
                            MenuItem(
                                icon: "car.fill",
                                title: "Ville",
                                color: .blue
                            ) {
                                showingCity = true
                            }
                            
                            MenuItem(
                                icon: "clock.arrow.circlepath",
                                title: "Historique des commandes",
                                color: AppColors.accentOrange
                            ) {
                                showingHistory = true
                            }
                            
                            MenuItem(
                                icon: "bell.fill",
                                title: "Notifications",
                                color: AppColors.accentOrange
                            ) {
                                showingNotifications = true
                            }
                            
                            MenuItem(
                                icon: "shield.checkered",
                                title: "Sécurité",
                                color: .green
                            ) {
                                showingSecurity = true
                            }
                            
                            MenuItem(
                                icon: "gearshape.fill",
                                title: "Paramètres",
                                color: .gray
                            ) {
                                showingSettings = true
                            }
                            
                            MenuItem(
                                icon: "questionmark.circle.fill",
                                title: "Aide et Assistance",
                                color: .blue
                            ) {
                                showingHelp = true
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bouton "Passer en Mode conducteur" - Uniquement pour les non-clients
                    // Les clients n'ont pas accès à cette option
                    if authViewModel.currentUser?.role != .client {
                        Button(action: {
                            showingDriverMode = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bicycle")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("Passer en Mode conducteur")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: 280)
                .background(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 0)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                RideHistoryView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingHistory = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationStack {
                NotificationsView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingNotifications = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSecurity) {
            NavigationStack {
                SecurityView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingSecurity = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(authManager)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingSettings = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                HelpView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingHelp = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSupport) {
            ClientSupportView()
        }
        .sheet(isPresented: $showingCity) {
            NavigationStack {
                CityView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                showingCity = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingDriverMode) {
            DriverMainView()
                .environmentObject(authViewModel)
        }
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 46)
    }
}

#Preview {
    SideMenuView(isPresented: .constant(true))
        .environmentObject(AuthViewModel())
}

