//
//  SavedAddressesView.swift
//  Tshiakani VTC
//
//  Écran de gestion des adresses enregistrées (simplifié)
//

import SwiftUI

struct SavedAddressesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var addressViewModel = AddressViewModel()
    @State private var showingAddAddress = false
    
    var body: some View {
        List {
            if addressViewModel.savedAddresses.isEmpty {
                Section {
                    VStack(spacing: AppDesign.spacingM) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentOrange.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .blur(radius: 10)
                            
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(AppColors.accentOrange)
                        }
                        
                        Text("Aucune adresse enregistrée")
                            .font(AppTypography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Ajoutez vos adresses fréquentes pour commander plus rapidement")
                            .font(AppTypography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppDesign.spacingL)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppDesign.spacingXXL)
                }
            } else {
                ForEach(addressViewModel.savedAddresses) { address in
                    AddressRow(address: address)
                }
                .onDelete(perform: deleteAddresses)
            }
        }
        .navigationTitle("Adresses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticFeedback.medium()
                    showingAddAddress = true
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accentOrange)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Ajouter une adresse")
                .accessibilityHint("Ajouter une nouvelle adresse enregistrée")
            }
        }
        .sheet(isPresented: $showingAddAddress) {
            AddAddressView { address in
                addressViewModel.saveAddress(address)
            }
        }
        .onAppear {
            addressViewModel.loadSavedAddresses()
        }
        .onChange(of: addressViewModel.errorMessage) { _, error in
            if let error = error {
                print("Erreur: \(error)")
            }
        }
    }
    
    private func deleteAddresses(at offsets: IndexSet) {
        for index in offsets {
            let address = addressViewModel.savedAddresses[index]
            addressViewModel.deleteAddress(address)
        }
    }
}


// MARK: - Address Row

struct AddressRow: View {
    let address: SavedAddress
    
    var body: some View {
        HStack(spacing: AppDesign.spacingM) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentOrange.opacity(0.2), AppColors.accentOrange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.accentOrange)
            }
            .shadow(color: AppColors.accentOrange.opacity(0.2), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: AppDesign.spacingXS) {
                Text(address.name)
                    .font(AppTypography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text(address.address)
                    .font(AppTypography.caption())
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, AppDesign.spacingS)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Address View

struct AddAddressView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var showingMapPicker = false
    @State private var selectedLocation: Location?
    
    let onSave: (SavedAddress) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Nom (ex: Maison, Bureau)", text: $name)
                    TextField("Adresse", text: $address)
                }
                
                Section {
                    Button(action: {
                        showingMapPicker = true
                    }) {
                        HStack {
                            Text("Choisir sur la carte")
                            Spacer()
                            Image(systemName: "map")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nouvelle adresse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveAddress()
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapLocationPickerViewWrapper(
                    selectedLocation: $selectedLocation,
                    address: $address
                )
            }
        }
    }
    
    private func saveAddress() {
        let location = selectedLocation ?? Location(
            latitude: -4.3276,
            longitude: 15.3136,
            address: address
        )
        
        let savedAddress = SavedAddress(
            name: name,
            address: address,
            location: location
        )
        
        onSave(savedAddress)
        dismiss()
    }
}

// MARK: - MapLocationPickerView Wrapper

struct MapLocationPickerViewWrapper: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: Location?
    @Binding var address: String
    @State private var tempLocation: Location?
    @State private var tempAddress: String = ""
    
    var body: some View {
        MapLocationPickerView(
            selectedLocation: $tempLocation,
            address: $tempAddress
        )
        .onAppear {
            tempLocation = selectedLocation
            tempAddress = address
        }
        .onDisappear {
            if let location = tempLocation {
                selectedLocation = location
                address = tempAddress.isEmpty ? (location.address ?? "") : tempAddress
            }
        }
    }
}

#Preview {
    let authViewModel = AuthViewModel()
    return NavigationStack {
        SavedAddressesView()
            .environmentObject(authViewModel)
    }
}

