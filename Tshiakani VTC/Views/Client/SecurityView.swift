//
//  SecurityView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import CoreLocation

struct SecurityView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel = SettingsViewModel(authViewModel: AuthViewModel())
    @StateObject private var sosViewModel = SOSViewModel()
    @State private var showingEmergencyAlert = false
    @State private var showingShareSheet = false
    @State private var showingPasswordChange = false
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    
    var body: some View {
        mainContent
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Sécurité")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Urgence", isPresented: $showingEmergencyAlert) {
                emergencyAlertButtons
            } message: {
                Text("Voulez-vous activer l'alerte SOS ou appeler les services d'urgence ?")
            }
            .sheet(isPresented: $showingPasswordChange) {
                passwordChangeSheet
            }
            .onAppear {
                settingsViewModel.loadSettings()
                sosViewModel.loadEmergencyContacts()
            }
            .onChange(of: settingsViewModel.errorMessage) { _, error in
                if error != nil {
                    showingError = true
                }
            }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                emergencyButton
                accountSecuritySection
                locationSharingSection
                securityTipsSection
            }
            .padding()
        }
    }
    
    private var emergencyAlertButtons: some View {
        Group {
            Button("Activer l'alerte SOS", role: .destructive) {
                Task {
                    await sosViewModel.activateSOS()
                }
            }
            Button("Appeler les secours", role: .destructive) {
                if let contact = sosViewModel.emergencyContacts.first {
                    sosViewModel.callEmergencyContact(contact)
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }
    
    private var passwordChangeSheet: some View {
        NavigationStack {
            Form {
                Section("Changement de mot de passe") {
                    SecureField("Ancien mot de passe", text: $oldPassword)
                    SecureField("Nouveau mot de passe", text: $newPassword)
                    SecureField("Confirmer le mot de passe", text: $confirmPassword)
                }
            }
            .navigationTitle("Changer le mot de passe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showingPasswordChange = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    savePasswordButton
                }
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(settingsViewModel.errorMessage ?? "Les mots de passe ne correspondent pas")
            }
        }
    }
    
    private var savePasswordButton: some View {
        Button("Enregistrer") {
            Task {
                await savePassword()
            }
        }
        .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || settingsViewModel.isLoading)
    }
    
    private func savePassword() async {
        if newPassword == confirmPassword {
            let success = await settingsViewModel.changePassword(
                currentPassword: oldPassword,
                newPassword: newPassword
            )
            if success {
                showingPasswordChange = false
                oldPassword = ""
                newPassword = ""
                confirmPassword = ""
            } else {
                showingError = true
            }
        } else {
            showingError = true
        }
    }
    
    // MARK: - Subviews
    
    private var emergencyButton: some View {
        Button(action: {
            showingEmergencyAlert = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                Text("URGENCE")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Appuyez en cas d'urgence")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding()
    }
    
    private var accountSecuritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sécurité du compte")
                .font(.headline)
            
            Button(action: {
                showingPasswordChange = true
            }) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Text("Changer le mot de passe")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var locationSharingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Partage de position")
                .font(.headline)
            
            Toggle(isOn: Binding(
                get: { settingsViewModel.locationSharingEnabled },
                set: { newValue in
                    Task {
                        await settingsViewModel.setLocationSharingEnabled(newValue)
                    }
                }
            )) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text("Partager ma position en temps réel")
                }
            }
            
            if settingsViewModel.locationSharingEnabled {
                emergencyContactsView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var emergencyContactsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contacts d'urgence")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(sosViewModel.emergencyContacts) { contact in
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.red)
                    Text(contact.name)
                    Spacer()
                    Button(action: {
                        sosViewModel.callEmergencyContact(contact)
                    }) {
                        Text("Appeler")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var securityTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conseils de sécurité")
                .font(.headline)
            
            SecurityTip(icon: "checkmark.shield.fill", text: "Vérifiez toujours les informations du conducteur avant de monter")
            SecurityTip(icon: "checkmark.shield.fill", text: "Partagez votre trajet avec un proche")
            SecurityTip(icon: "checkmark.shield.fill", text: "Restez vigilant pendant le trajet")
            SecurityTip(icon: "checkmark.shield.fill", text: "En cas d'urgence, utilisez le bouton d'urgence")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SecurityTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SecurityView()
            .environmentObject(AuthViewModel())
    }
}

