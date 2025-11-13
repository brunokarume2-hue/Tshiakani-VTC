//
//  CodeVerificationScreen.swift
//  Tshiakani VTC
//
//  Écran de vérification du code WhatsApp à 6 chiffres
//

import SwiftUI

struct CodeVerificationScreen: View {
    let phoneNumber: String
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Int?
    @State private var navigateToAccountSelection = false
    
    @State private var codeFields: [String] = Array(repeating: "", count: 6)
    
    private func updateCodeFromFields() {
        let fullCode = codeFields.joined()
        viewModel.verificationCode = fullCode
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icône WhatsApp
                Image(systemName: "message.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                // Message
                VStack(spacing: 12) {
                    Text("Consultez votre WhatsApp")
                        .font(.system(size: 28, weight: .bold, design: .default))
                    
                    Text("Nous avons envoyé un code à")
                        .font(.system(size: 17, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text(phoneNumber)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
                // Champs de code à 6 chiffres
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        TextField("", text: Binding(
                            get: { codeFields[index] },
                            set: { newValue in
                                handleCodeInput(at: index, newValue: newValue)
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .frame(width: 50, height: 60)
                        .multilineTextAlignment(.center)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($focusedField, equals: index)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == index ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .onChange(of: codeFields) { _, _ in
                    updateCodeFromFields()
                    // Vérifier automatiquement quand le code est complet
                    let fullCode = codeFields.joined()
                    if fullCode.count == 6 {
                        Task {
                            await viewModel.verifyOTP()
                            if viewModel.isCodeVerified {
                                navigateToAccountSelection = true
                            }
                        }
                    }
                }
                
                // Boutons secondaires
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await viewModel.resendOTP()
                        }
                    }) {
                        Text("Renvoyer le code")
                            .font(.system(size: 15, design: .default))
                            .foregroundColor(.blue)
                    }
                    .disabled(!viewModel.canResendOTP || viewModel.isLoading)
                    
                    Button(action: {
                        Task {
                            await viewModel.sendOTP()
                        }
                    }) {
                        Text("Envoyer par SMS")
                            .font(.system(size: 15, design: .default))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)
                }
                
                if !viewModel.canResendOTP && viewModel.resendTimer > 0 {
                    Text("Renvoyer dans \(viewModel.resendTimer) secondes")
                        .font(.system(size: 13, design: .default))
                        .foregroundColor(.secondary)
                }
                
                // Afficher les erreurs
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, design: .default))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
                // Indicateur de chargement
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Vérification")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                }
            }
            .onAppear {
                focusedField = 0
                if !viewModel.otpSent {
                    Task {
                        await viewModel.sendOTP()
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToAccountSelection) {
                AccountSelectionScreen(viewModel: viewModel)
            }
        }
    }
    
    private func handleCodeInput(at index: Int, newValue: String) {
        // Ne garder que les chiffres
        var cleanedValue = newValue.filter { $0.isNumber }
        
        // Limiter à un seul chiffre
        if cleanedValue.count > 1 {
            cleanedValue = String(cleanedValue.prefix(1))
        }
        
        // Mettre à jour le champ
        codeFields[index] = cleanedValue
        
        // Si un chiffre est entré et qu'il reste des champs, passer au suivant
        if !cleanedValue.isEmpty && index < 5 {
            focusedField = index + 1
        }
        
        // Si un chiffre est supprimé et qu'il y a un chiffre dans le champ suivant, déplacer le focus
        if cleanedValue.isEmpty && index > 0 {
            focusedField = index - 1
        }
    }
}

#Preview {
    CodeVerificationScreen(phoneNumber: "+243 820 098 808", viewModel: OnboardingViewModel())
}


