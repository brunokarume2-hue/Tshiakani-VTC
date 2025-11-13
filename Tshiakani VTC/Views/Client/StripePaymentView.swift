//
//  StripePaymentView.swift
//  Tshiakani VTC
//
//  Vue de paiement avec intégration Stripe
//

import SwiftUI

struct StripePaymentView: View {
    let ride: Ride
    let onPaymentSuccess: () -> Void
    let onPaymentCancel: () -> Void
    
    @StateObject private var stripeService = StripeService.shared
    @State private var cardNumber: String = ""
    @State private var expiryMonth: Int = 1
    @State private var expiryYear: Int = Calendar.current.component(.year, from: Date())
    @State private var cvc: String = ""
    @State private var cardholderName: String = ""
    
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false
    
    private var amount: Double {
        ride.finalPrice ?? ride.estimatedPrice
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec montant
                    paymentHeader
                    
                    // Formulaire de carte
                    cardForm
                    
                    // Bouton de paiement
                    paymentButton
                    
                    // Message d'erreur
                    if let error = errorMessage {
                        errorView(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Paiement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        onPaymentCancel()
                    }
                }
            }
            .alert("Paiement réussi", isPresented: $showSuccess) {
                Button("OK") {
                    onPaymentSuccess()
                }
            } message: {
                Text("Votre paiement de \(formatCurrency(amount)) a été traité avec succès.")
            }
        }
    }
    
    private var paymentHeader: some View {
        VStack(spacing: 12) {
            Text("Montant à payer")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(formatCurrency(amount))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Course #\(ride.id)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var cardForm: some View {
        VStack(spacing: 16) {
            // Nom du titulaire
            VStack(alignment: .leading, spacing: 8) {
                Text("Nom sur la carte")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Jean Dupont", text: $cardholderName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
            }
            
            // Numéro de carte
            VStack(alignment: .leading, spacing: 8) {
                Text("Numéro de carte")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("1234 5678 9012 3456", text: $cardNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .onChange(of: cardNumber) { oldValue, newValue in
                        // Formater le numéro de carte (ajouter des espaces)
                        cardNumber = formatCardNumber(newValue)
                    }
            }
            
            // Date d'expiration et CVC
            HStack(spacing: 16) {
                // Mois
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mois")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Mois", selection: $expiryMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(String(format: "%02d", month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
                
                // Année
                VStack(alignment: .leading, spacing: 8) {
                    Text("Année")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Année", selection: $expiryYear) {
                        ForEach(expiryYear...(expiryYear + 10), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
                
                // CVC
                VStack(alignment: .leading, spacing: 8) {
                    Text("CVC")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("123", text: $cvc)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 80)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var paymentButton: some View {
        Button(action: processPayment) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "lock.fill")
                    Text("Payer \(formatCurrency(amount))")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid && !isProcessing ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isProcessing)
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        cardNumber.replacingOccurrences(of: " ", with: "").count >= 13 &&
        expiryMonth >= 1 && expiryMonth <= 12 &&
        expiryYear >= Calendar.current.component(.year, from: Date()) &&
        !cvc.isEmpty && cvc.count >= 3 &&
        !cardholderName.isEmpty
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        let chunks = cleaned.chunked(into: 4)
        return chunks.joined(separator: " ")
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CDF"
        formatter.locale = Locale(identifier: "fr_CD")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) CDF"
    }
    
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func processPayment() {
        guard isFormValid else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Générer un token Stripe
                let stripeToken = try await stripeService.createPaymentToken(
                    cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
                    expiryMonth: expiryMonth,
                    expiryYear: expiryYear,
                    cvc: cvc,
                    cardholderName: cardholderName
                )
                
                // 2. Pré-autoriser le paiement
                let paymentIntent = try await stripeService.preauthorizePayment(
                    rideId: ride.id,
                    stripeToken: stripeToken,
                    amount: amount
                )
                
                // 3. Confirmer le paiement
                let confirmedIntent = try await stripeService.confirmPayment(
                    paymentIntentId: paymentIntent.id
                )
                
                // Vérifier que le paiement a réussi
                if confirmedIntent.status == "succeeded" {
                    await MainActor.run {
                        isProcessing = false
                        showSuccess = true
                    }
                } else {
                    await MainActor.run {
                        isProcessing = false
                        errorMessage = "Le paiement n'a pas pu être confirmé. Statut: \(confirmedIntent.status)"
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Extension pour diviser une chaîne en chunks
extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var index = startIndex
        
        while index < endIndex {
            let nextIndex = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[index..<nextIndex]))
            index = nextIndex
        }
        
        return chunks
    }
}

#Preview {
    StripePaymentView(
        ride: Ride(
            id: "1",
            clientId: "1",
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3159, address: "Point A"),
            dropoffLocation: Location(latitude: -4.3277, longitude: 15.3160, address: "Point B"),
            status: .completed,
            estimatedPrice: 5000.0,
            finalPrice: 5000.0
        ),
        onPaymentSuccess: {},
        onPaymentCancel: {}
    )
}

