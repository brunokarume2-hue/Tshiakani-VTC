//
//  PhoneInputScreen.swift
//  Tshiakani VTC
//
//  Écran de saisie du numéro de téléphone avec validation
//

import SwiftUI

struct PhoneInputScreen: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @FocusState private var isPhoneFieldFocused: Bool
    @State private var navigateToCodeVerification = false
    
    private let countryCode = "+243"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icône téléphone
                Image(systemName: "phone.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Message
                VStack(spacing: 12) {
                    Text("Entrez votre numéro")
                        .font(.system(size: 28, weight: .bold, design: .default))
                    
                    Text("Nous enverrons un code de confirmation à ce numéro")
                        .font(.system(size: 17, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Champ de saisie
                HStack(spacing: 12) {
                    Text(countryCode)
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .frame(width: 60)
                    
                    TextField("820 098 808", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .font(.system(size: 17, design: .default))
                        .focused($isPhoneFieldFocused)
                        .onChange(of: viewModel.phoneNumber) { _, newValue in
                            viewModel.validatePhoneNumber(newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPhoneFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
                .padding(.horizontal, 24)
                
                // Liens légaux
                VStack(spacing: 12) {
                    Link("Contrat utilisateur", destination: URL(string: "https://tshiakanivtc.com/terms")!)
                        .font(.system(size: 15, design: .default))
                    
                    Link("Contrat de licence", destination: URL(string: "https://tshiakanivtc.com/license")!)
                        .font(.system(size: 15, design: .default))
                    
                    Link("Politique de confidentialité", destination: URL(string: "https://tshiakanivtc.com/privacy")!)
                        .font(.system(size: 15, design: .default))
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                // Bouton continuer
                Button(action: {
                    Task {
                        await viewModel.sendOTP()
                        if viewModel.otpSent {
                            navigateToCodeVerification = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continuer")
                                .font(.system(size: 17, weight: .semibold, design: .default))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isValidPhone && !viewModel.isLoading ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isValidPhone || viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Afficher les erreurs
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, design: .default))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Connexion")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                }
            }
            .onAppear {
                isPhoneFieldFocused = true
            }
            .navigationDestination(isPresented: $navigateToCodeVerification) {
                CodeVerificationScreen(phoneNumber: "\(countryCode) \(viewModel.phoneNumber)", viewModel: viewModel)
            }
        }
    }
}

#Preview {
    PhoneInputScreen()
}


