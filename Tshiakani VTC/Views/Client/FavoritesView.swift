//
//  FavoritesView.swift
//  Tshiakani VTC
//
//  Écran de gestion des favoris
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var showingAddFavorite = false
    @State private var selectedFavorite: SavedAddress?
    
    var body: some View {
        NavigationStack {
            List {
                if favoritesViewModel.favoriteAddresses.isEmpty {
                    // État vide
                    VStack(spacing: AppDesign.spacingL) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(AppColors.accentOrange.opacity(0.5))
                        
                        Text("Aucun favori")
                            .font(AppTypography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Ajoutez des adresses favorites pour un accès rapide")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppDesign.spacingXL)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppDesign.spacingXL)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    // Liste des favoris
                    ForEach(favoritesViewModel.favoriteAddresses) { favorite in
                        FavoriteRow(favorite: favorite) {
                            selectedFavorite = favorite
                            favoritesViewModel.useFavorite(favorite)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    _ = await favoritesViewModel.removeFavorite(favorite)
                                }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Favoris")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFavorite = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.accentOrange)
                    }
                }
            }
            .sheet(isPresented: $showingAddFavorite) {
                AddFavoriteView { address in
                    Task {
                        _ = await favoritesViewModel.addFavorite(address)
                    }
                }
            }
            .sheet(item: $selectedFavorite) { favorite in
                EditFavoriteView(favorite: favorite) { updatedFavorite in
                    Task {
                        _ = await favoritesViewModel.removeFavorite(favorite)
                        _ = await favoritesViewModel.addFavorite(updatedFavorite)
                    }
                }
            }
            .onAppear {
                favoritesViewModel.loadFavorites()
            }
            .onChange(of: favoritesViewModel.errorMessage) { _, error in
                if let error = error {
                    print("Erreur FavoritesView: \(error)")
                }
            }
        }
    }
}

struct FavoriteRow: View {
    let favorite: SavedAddress
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppDesign.spacingM) {
                // Icône
                Image(systemName: favorite.icon ?? "mappin.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.accentOrange)
                    .clipShape(Circle())
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.name)
                        .font(AppTypography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(favorite.address)
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.vertical, AppDesign.spacingS)
        }
        .buttonStyle(.plain)
    }
}

struct AddFavoriteView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var name = ""
    @State private var address = ""
    @State private var selectedLocation: Location?
    @State private var showingAddressSearch = false
    @State private var selectedIcon = "house.fill"
    
    let onAdd: (SavedAddress) -> Void
    
    var isFormValid: Bool {
        !name.isEmpty && selectedLocation != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Ex: Maison, Travail", text: $name)
                }
                
                Section("Adresse") {
                    Button(action: {
                        showingAddressSearch = true
                    }) {
                        HStack {
                            Text(address.isEmpty ? "Choisir une adresse" : address)
                                .foregroundColor(address.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                
                Section("Icône") {
                    Picker("Icône", selection: $selectedIcon) {
                        Label("Maison", systemImage: "house.fill").tag("house.fill")
                        Label("Travail", systemImage: "briefcase.fill").tag("briefcase.fill")
                        Label("École", systemImage: "graduationcap.fill").tag("graduationcap.fill")
                        Label("Hôpital", systemImage: "cross.circle.fill").tag("cross.circle.fill")
                        Label("Restaurant", systemImage: "fork.knife").tag("fork.knife")
                        Label("Autre", systemImage: "mappin.circle.fill").tag("mappin.circle.fill")
                    }
                }
            }
            .navigationTitle("Nouveau favori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if let location = selectedLocation {
                            let favorite = SavedAddress(
                                id: UUID().uuidString,
                                name: name,
                                address: address,
                                location: location,
                                icon: selectedIcon,
                                isFavorite: true
                            )
                            onAdd(favorite)
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? AppColors.accentOrange : AppColors.secondaryText)
                }
            }
            .sheet(isPresented: $showingAddressSearch) {
                AddressSearchView(selectedLocation: Binding(
                    get: { selectedLocation },
                    set: { location in
                        selectedLocation = location
                        if let location = location {
                            address = location.address ?? "\(location.latitude), \(location.longitude)"
                        }
                    }
                ), address: $address)
            }
        }
    }
}

struct EditFavoriteView: View {
    let favorite: SavedAddress
    @Environment(\.dismiss) var dismiss
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var name: String
    @State private var address: String
    @State private var selectedIcon: String
    @State private var showingAddressSearch = false
    @State private var selectedLocation: Location?
    
    let onSave: (SavedAddress) -> Void
    
    init(favorite: SavedAddress, onSave: @escaping (SavedAddress) -> Void) {
        self.favorite = favorite
        self.onSave = onSave
        _name = State(initialValue: favorite.name)
        _address = State(initialValue: favorite.address)
        _selectedIcon = State(initialValue: favorite.icon ?? "mappin.circle.fill")
        _selectedLocation = State(initialValue: favorite.location)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Ex: Maison, Travail", text: $name)
                }
                
                Section("Adresse") {
                    Button(action: {
                        showingAddressSearch = true
                    }) {
                        HStack {
                            Text(address.isEmpty ? "Choisir une adresse" : address)
                                .foregroundColor(address.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                
                Section("Icône") {
                    Picker("Icône", selection: $selectedIcon) {
                        Label("Maison", systemImage: "house.fill").tag("house.fill")
                        Label("Travail", systemImage: "briefcase.fill").tag("briefcase.fill")
                        Label("École", systemImage: "graduationcap.fill").tag("graduationcap.fill")
                        Label("Hôpital", systemImage: "cross.circle.fill").tag("cross.circle.fill")
                        Label("Restaurant", systemImage: "fork.knife").tag("fork.knife")
                        Label("Autre", systemImage: "mappin.circle.fill").tag("mappin.circle.fill")
                    }
                }
            }
            .navigationTitle("Modifier le favori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        let location = selectedLocation ?? favorite.location
                        let updatedFavorite = SavedAddress(
                            id: favorite.id,
                            name: name,
                            address: address,
                            location: location,
                            icon: selectedIcon,
                            isFavorite: true
                        )
                        onSave(updatedFavorite)
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
            .sheet(isPresented: $showingAddressSearch) {
                AddressSearchView(selectedLocation: Binding(
                    get: { selectedLocation },
                    set: { location in
                        selectedLocation = location
                        if let location = location {
                            address = location.address ?? "\(location.latitude), \(location.longitude)"
                        }
                    }
                ), address: $address)
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(AuthViewModel())
}

