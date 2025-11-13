//
//  GooglePlacesAutocompleteView.swift
//  Tshiakani VTC
//
//  Vue pour l'autocomplétion d'adresses avec Google Places SDK
//

import SwiftUI

struct GooglePlacesAutocompleteView: View {
    @Binding var selectedLocation: Location?
    @Binding var address: String
    @StateObject private var placesService = GooglePlacesService.shared
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Rechercher une adresse...", text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            placesService.search(query: newValue)
                        }
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            placesService.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()
                
                // Résultats de recherche
                if placesService.isSearching {
                    ProgressView("Recherche en cours...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if placesService.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Aucun résultat")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Essayez avec un autre nom d'adresse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if placesService.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Commencez à taper une adresse")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Ex: 123 Avenue, Kinshasa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(placesService.searchResults) { result in
                        Button(action: {
                            selectPlace(result)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.primaryText)
                                        .foregroundColor(.primary)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    if !result.secondaryText.isEmpty {
                                        Text(result.secondaryText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Message d'erreur
                if let errorMessage = placesService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Rechercher une adresse")
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
    
    private func selectPlace(_ result: PlaceAutocompleteResult) {
        Task {
            do {
                let placeDetails = try await placesService.getPlaceDetails(placeID: result.placeID)
                let location = placesService.location(from: placeDetails)
                
                await MainActor.run {
                    selectedLocation = location
                    address = location.address ?? result.primaryText
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ Erreur lors de la sélection: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    GooglePlacesAutocompleteView(
        selectedLocation: .constant(nil),
        address: .constant("")
    )
}

