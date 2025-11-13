//
//  BackendConnectionTestView.swift
//  Tshiakani VTC
//
//  Vue pour tester la connexion au backend
//

import SwiftUI

struct BackendConnectionTestView: View {
    @StateObject private var testService = BackendConnectionTestService.shared
    @State private var isTesting = false
    @State private var connectionInfo: BackendConnectionTestService.ConnectionInfo?
    
    var body: some View {
        List {
            // Section Informations de Connexion
            Section("Informations de Connexion") {
                if let info = connectionInfo {
                    BackendInfoRow(label: "API Base URL", value: info.apiBaseURL)
                    BackendInfoRow(label: "Socket Base URL", value: info.socketBaseURL)
                    BackendInfoRow(label: "Token JWT", value: info.hasAuthToken ? "✅ Présent" : "❌ Absent")
                    if info.hasAuthToken {
                        BackendInfoRow(label: "Token (preview)", value: info.authToken)
                    }
                }
            }
            
            // Section Tests
            Section("Tests de Connexion") {
                Button(action: {
                    Task {
                        isTesting = true
                        connectionInfo = testService.getConnectionInfo()
                        await testService.testConnection()
                        isTesting = false
                    }
                }) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Tester la connexion")
                    }
                }
                .disabled(isTesting)
                
                if testService.isBackendConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Backend connecté")
                            .foregroundColor(.green)
                    }
                } else if !testService.testResults.isEmpty {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Backend non connecté")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Section Résultats des Tests
            if !testService.testResults.isEmpty {
                Section("Résultats des Tests") {
                    ForEach(testService.testResults) { result in
                        TestResultRow(result: result)
                    }
                }
            }
            
            // Section Configuration
            Section("Configuration") {
                NavigationLink {
                    BackendConfigurationView()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Configurer l'URL du backend")
                    }
                }
            }
            
            // Section Erreurs
            if let error = testService.lastError {
                Section("Dernière Erreur") {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Test de Connexion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            connectionInfo = testService.getConnectionInfo()
        }
    }
}

struct BackendInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

struct TestResultRow: View {
    let result: BackendConnectionTestService.TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                Text(result.testName)
                    .font(.headline)
                Spacer()
            }
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatDate(result.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct BackendConfigurationView: View {
    @AppStorage("api_base_url") private var apiBaseURL: String = ""
    @AppStorage("socket_base_url") private var socketBaseURL: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var showingResetConfirmation = false
    
    // Valeurs par défaut selon l'environnement
    private var defaultAPIURL: String {
        #if DEBUG
        #if targetEnvironment(simulator)
        return "http://localhost:3000/api"
        #else
        return "http://192.168.1.79:3000/api"
        #endif
        #else
        return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
        #endif
    }
    
    private var defaultSocketURL: String {
        #if DEBUG
        #if targetEnvironment(simulator)
        return "http://localhost:3000"
        #else
        return "http://192.168.1.79:3000"
        #endif
        #else
        return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
        #endif
    }
    
    var body: some View {
        Form {
            Section("URLs du Backend") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Base URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("http://192.168.1.79:3000/api", text: $apiBaseURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Socket Base URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("http://192.168.1.79:3000", text: $socketBaseURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
            }
            
            Section("Valeurs par Défaut Actuelles") {
                HStack {
                    Text("API Base URL")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(defaultAPIURL)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
                
                HStack {
                    Text("Socket Base URL")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(defaultSocketURL)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Réinitialiser aux valeurs par défaut")
                        Spacer()
                    }
                }
            }
            
            Section("Information") {
                Text("Laissez les champs vides pour utiliser les valeurs par défaut.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                #if DEBUG
                #if targetEnvironment(simulator)
                Text("Mode: DEBUG - Simulateur (localhost)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                #else
                Text("Mode: DEBUG - Appareil réel (IP: 192.168.1.79)")
                    .font(.caption2)
                    .foregroundColor(.orange)
                #endif
                #else
                Text("Mode: RELEASE - Production (Cloud Run)")
                    .font(.caption2)
                    .foregroundColor(.green)
                #endif
            }
        }
        .navigationTitle("Configuration Backend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Terminé") {
                    dismiss()
                }
            }
        }
        .alert("Réinitialiser", isPresented: $showingResetConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Réinitialiser", role: .destructive) {
                apiBaseURL = ""
                socketBaseURL = ""
            }
        } message: {
            Text("Voulez-vous réinitialiser les URLs aux valeurs par défaut ?")
        }
    }
}

#Preview {
    NavigationStack {
        BackendConnectionTestView()
    }
}

