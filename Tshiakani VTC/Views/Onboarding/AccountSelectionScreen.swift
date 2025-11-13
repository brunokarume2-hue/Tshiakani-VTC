//
//  AccountSelectionScreen.swift
//  Tshiakani VTC
//
//  Écran de sélection de compte avec détection automatique
//

import SwiftUI

struct AccountSelectionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var navigateToHome = false
    @State private var isSearching = false
    
    // Compte détecté (simulation)
    private let detectedAccount = (firstName: "Bruno", lastName: "Karume")
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icône compte
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Message
                VStack(spacing: 16) {
                    Text("Nous avons identifié un compte")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .multilineTextAlignment(.center)
                    
                    Text("avec ces renseignements")
                        .font(.system(size: 17, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Compte détecté
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("\(detectedAccount.firstName) \(detectedAccount.lastName)")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: {
                        firstName = detectedAccount.firstName
                        lastName = detectedAccount.lastName
                        viewModel.selectRole(.client)
                        viewModel.completeOnboarding()
                        navigateToHome = true
                    }) {
                        Text("Utiliser ce compte")
                            .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Option de recherche
                VStack(spacing: 16) {
                    Text("Ou rechercher par nom")
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        TextField("Prénom", text: $firstName)
                            .textContentType(.givenName)
                            .font(.system(size: 17, design: .default))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        TextField("Nom", text: $lastName)
                            .textContentType(.familyName)
                            .font(.system(size: 17, design: .default))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: {
                        isSearching = true
                        // Logique de recherche
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSearching = false
                            viewModel.selectRole(.client)
                            viewModel.completeOnboarding()
                            navigateToHome = true
                        }
                    }) {
                        HStack {
                            if isSearching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Rechercher")
                                    .font(.system(size: 17, weight: .semibold, design: .default))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background((!firstName.isEmpty || !lastName.isEmpty) ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(firstName.isEmpty && lastName.isEmpty || isSearching)
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sélection de compte")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeScreen()
            }
        }
    }
}

#Preview {
    AccountSelectionScreen(viewModel: OnboardingViewModel())
        .environmentObject(AuthManager())
}

