//
//  AddressSearchView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct AddressSearchView: View {
    @Binding var selectedLocation: Location?
    @Binding var address: String
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche épurée
                HStack(spacing: AppDesign.spacingM) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                    
                    TextField("Rechercher une adresse...", text: $searchText)
                        .font(AppTypography.headline())
                        .onChange(of: searchText) { _, newValue in
                            // La recherche est déclenchée automatiquement par le debounce dans AddressViewModel
                            addressViewModel.searchQuery = newValue
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(AppDesign.animationFast) {
                                searchText = ""
                                addressViewModel.searchQuery = ""
                                addressViewModel.searchResults = []
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .accessibilityLabel("Effacer")
                        .accessibilityHint("Effacer la recherche")
                    }
                }
                .padding(20)
                .background(.regularMaterial)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, AppDesign.spacingM)
                
                // Résultats de recherche
                if addressViewModel.isSearching {
                    VStack(spacing: AppDesign.spacingL) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AppColors.accentOrange)
                        Text("Recherche en cours...")
                            .font(AppTypography.headline())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if addressViewModel.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: AppDesign.spacingL) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText.opacity(0.5))
                        Text("Aucun résultat")
                            .font(AppTypography.title3(weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                        Text("Essayez avec d'autres mots-clés")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(addressViewModel.searchResults.indices, id: \.self) { index in
                        let result = addressViewModel.searchResults[index]
                        Button(action: {
                            HapticFeedback.medium()
                            selectAddress(result)
                        }) {
                            HStack(spacing: AppDesign.spacingM) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(AppColors.accentOrange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.primaryText)
                                        .font(AppTypography.headline(weight: .regular))
                                        .foregroundColor(AppColors.primaryText)
                                    if !result.secondaryText.isEmpty {
                                        Text(result.secondaryText)
                                            .font(AppTypography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText.opacity(0.5))
                            }
                            .padding(.vertical, AppDesign.spacingM)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                // Afficher les erreurs
                if let errorMessage = addressViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Rechercher une adresse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Text("Annuler")
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.accentOrange)
                    }
                }
            }
        }
    }
    
    private func selectAddress(_ result: PlaceAutocompleteResult) {
        Task {
            await addressViewModel.selectPlace(result)
            
            if let location = addressViewModel.selectedLocation {
                await MainActor.run {
                    selectedLocation = location
                    address = location.address ?? result.primaryText
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AddressSearchView(selectedLocation: .constant(nil), address: .constant(""))
}
