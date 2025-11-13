//
//  HomeScreen.swift
//  Tshiakani VTC
//
//  Écran d'accueil avec géolocalisation et suggestions
//

import SwiftUI
import MapKit

struct HomeScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var showAddressInput = false
    @State private var showSettings = false
    @State private var navigateToProfile = false
    
    // Suggestions de destinations (exemple)
    private let destinationSuggestions = [
        Destination(name: "Aéroport de N'Djili", eta: "25 min", price: "45,000 CDF"),
        Destination(name: "Gombe", eta: "15 min", price: "34,000 CDF"),
        Destination(name: "Kintambo", eta: "20 min", price: "38,000 CDF"),
        Destination(name: "Lingwala", eta: "12 min", price: "30,000 CDF")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Message de géolocalisation
                    if locationManager.authorizationStatus != .authorizedWhenInUse &&
                       locationManager.authorizationStatus != .authorizedAlways {
                        locationWarningCard
                    }
                    
                    // Section promo
                    promoCard
                    
                    // Suggestions de destinations
                    destinationsSection
                }
                .padding()
            }
            .navigationTitle("Tshiakani VTC")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigateToProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddressInput) {
                AddressInputView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileScreen()
            }
        }
    }
    
    private var locationWarningCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activez les services de géolocalisation")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                    
                    Text("Nous ne savons pas où vous êtes")
                        .font(.system(size: 15, design: .default))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    showAddressInput = true
                }) {
                    Text("Saisir adresse")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showSettings = true
                }) {
                    Text("Configurer")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var promoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                
                Text("Offre spéciale")
                    .font(.system(size: 20, weight: .bold, design: .default))
            }
            
            Text("Des courses à partir de 34,000 CDF!")
                .font(.system(size: 17, design: .default))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.1), Color.orange.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Destinations populaires")
                .font(.system(size: 22, weight: .bold, design: .default))
                .padding(.horizontal, 4)
            
            ForEach(destinationSuggestions, id: \.name) { destination in
                DestinationRow(destination: destination)
            }
        }
    }
}

struct Destination {
    let name: String
    let eta: String
    let price: String
}

struct DestinationRow: View {
    let destination: Destination
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                
                HStack(spacing: 12) {
                    Label(destination.eta, systemImage: "clock.fill")
                        .font(.system(size: 15, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(destination.price)
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddressInputView: View {
    @Environment(\.dismiss) var dismiss
    @State private var address = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Entrez votre adresse", text: $address, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Saisir adresse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}

