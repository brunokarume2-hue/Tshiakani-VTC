//
//  ScheduledRideView.swift
//  Tshiakani VTC
//
//  Écran de réservation programmée
//

import SwiftUI

struct ScheduledRideView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var scheduledRideViewModel = ScheduledRideViewModel()
    @StateObject private var addressViewModel = AddressViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    
    @State private var showingPickupSearch = false
    @State private var showingDropoffSearch = false
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var navigateToConfirmation = false
    
    private var pickupAddress: String { scheduledRideViewModel.pickupLocation?.address ?? "" }
    private var dropoffAddress: String { scheduledRideViewModel.dropoffLocation?.address ?? "" }
    
    var isFormValid: Bool {
        scheduledRideViewModel.pickupLocation != nil &&
        scheduledRideViewModel.dropoffLocation != nil &&
        scheduledRideViewModel.selectedDate > Date() &&
        vehicleViewModel.selectedVehicleType != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.spacingXL) {
                    // En-tête
                    VStack(spacing: AppDesign.spacingM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(AppColors.accentOrange)
                        
                        Text("Réservation programmée")
                            .font(AppTypography.largeTitle(weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Réservez votre trajet à l'avance")
                            .font(AppTypography.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, AppDesign.spacingM)
                    
                    // Section Adresses
                    VStack(spacing: AppDesign.spacingL) {
                        // Point de départ
                        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(AppColors.success)
                                
                                Text("Point de départ")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            Button(action: {
                                showingPickupSearch = true
                            }) {
                                HStack {
                                    Text(pickupAddress.isEmpty ? "Choisir le point de départ" : pickupAddress)
                                        .font(AppTypography.body())
                                        .foregroundColor(pickupAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(AppDesign.spacingM)
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppDesign.cornerRadiusM)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Destination
                        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                            HStack {
                                Image(systemName: "flag.circle.fill")
                                    .foregroundColor(AppColors.accentOrange)
                                
                                Text("Destination")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            Button(action: {
                                showingDropoffSearch = true
                            }) {
                                HStack {
                                    Text(dropoffAddress.isEmpty ? "Choisir la destination" : dropoffAddress)
                                        .font(AppTypography.body())
                                        .foregroundColor(dropoffAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(AppDesign.spacingM)
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppDesign.cornerRadiusM)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    
                    // Section Date et Heure
                    VStack(spacing: AppDesign.spacingL) {
                        // Date
                        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(AppColors.accentOrange)
                                
                                Text("Date")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            DatePicker(
                                "Sélectionner la date",
                                selection: $scheduledRideViewModel.selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding(AppDesign.spacingM)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppDesign.cornerRadiusM)
                        }
                        
                        // Heure
                        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(AppColors.accentOrange)
                                
                                Text("Heure")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            DatePicker(
                                "Sélectionner l'heure",
                                selection: $scheduledRideViewModel.selectedTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .padding(AppDesign.spacingM)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppDesign.cornerRadiusM)
                        }
                    }
                    .padding(.horizontal, AppDesign.spacingM)
                    
                    // Sélection de véhicule
                    if scheduledRideViewModel.pickupLocation != nil && scheduledRideViewModel.dropoffLocation != nil {
                        VStack(alignment: .leading, spacing: AppDesign.spacingS) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(AppColors.accentOrange)
                                
                                Text("Type de véhicule")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            VehicleSelectionView(
                                pickupLocation: scheduledRideViewModel.pickupLocation,
                                dropoffLocation: scheduledRideViewModel.dropoffLocation,
                                selectedVehicle: Binding(
                                    get: { vehicleViewModel.selectedVehicleType },
                                    set: { newType in
                                        if let newType = newType {
                                            vehicleViewModel.selectVehicle(newType)
                                            // Mettre à jour le prix estimé
                                            if let estimate = vehicleViewModel.getPriceEstimate(for: newType) {
                                                scheduledRideViewModel.estimatedPrice = estimate.price
                                                scheduledRideViewModel.estimatedDistance = estimate.distance
                                            }
                                        }
                                    }
                                ),
                                vehicleViewModel: vehicleViewModel
                            )
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                    }
                    
                    // Prix estimé
                    if isFormValid && scheduledRideViewModel.estimatedPrice > 0 {
                        VStack(spacing: AppDesign.spacingM) {
                            HStack {
                                Text("Prix estimé")
                                    .font(AppTypography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Spacer()
                                
                                Text("\(Int(scheduledRideViewModel.estimatedPrice)) FC")
                                    .font(AppTypography.title2(weight: .bold))
                                    .foregroundColor(AppColors.accentOrange)
                            }
                            .padding(AppDesign.spacingM)
                            .background(AppColors.accentOrangeLight)
                            .cornerRadius(AppDesign.cornerRadiusM)
                        }
                        .padding(.horizontal, AppDesign.spacingM)
                    }
                    
                    // Bouton Réserver
                    Button(action: {
                        scheduleRide()
                    }) {
                        HStack {
                            if scheduledRideViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Réserver")
                                    .font(AppTypography.headline(weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(AppColors.accentOrange)
                    .cornerRadius(AppDesign.cornerRadiusL)
                    .buttonShadow()
                    .padding(.horizontal, AppDesign.spacingM)
                    .disabled(!isFormValid || scheduledRideViewModel.isLoading)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    Spacer()
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentOrange)
                }
            }
            .sheet(isPresented: $showingPickupSearch) {
                AddressSearchView(
                    selectedLocation: Binding(
                        get: { scheduledRideViewModel.pickupLocation },
                        set: { location in
                            scheduledRideViewModel.pickupLocation = location
                            vehicleViewModel.pickupLocation = location
                            if let location = location, let dropoff = scheduledRideViewModel.dropoffLocation {
                                vehicleViewModel.loadPriceEstimates(pickup: location, dropoff: dropoff)
                            }
                        }
                    ),
                    address: Binding(
                        get: { pickupAddress },
                        set: { _ in } // Read-only
                    )
                )
            }
            .sheet(isPresented: $showingDropoffSearch) {
                AddressSearchView(
                    selectedLocation: Binding(
                        get: { scheduledRideViewModel.dropoffLocation },
                        set: { location in
                            scheduledRideViewModel.dropoffLocation = location
                            vehicleViewModel.dropoffLocation = location
                            if let location = location, let pickup = scheduledRideViewModel.pickupLocation {
                                vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: location)
                            }
                        }
                    ),
                    address: Binding(
                        get: { dropoffAddress },
                        set: { _ in } // Read-only
                    )
                )
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(scheduledRideViewModel.errorMessage ?? "Une erreur est survenue")
            }
            .alert("Succès", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre réservation a été créée avec succès")
            }
            .onAppear {
                Task {
                    await scheduledRideViewModel.loadScheduledRides()
                }
                // Utiliser la position actuelle comme point de départ par défaut
                if let current = LocationService.shared.currentLocation {
                    scheduledRideViewModel.pickupLocation = current
                    vehicleViewModel.pickupLocation = current
                }
            }
            .onChange(of: scheduledRideViewModel.errorMessage) { _, error in
                if error != nil {
                    showingError = true
                }
            }
            .onChange(of: scheduledRideViewModel.pickupLocation) { _, newLocation in
                if let newLocation = newLocation, let dropoff = scheduledRideViewModel.dropoffLocation {
                    vehicleViewModel.loadPriceEstimates(pickup: newLocation, dropoff: dropoff)
                }
            }
            .onChange(of: scheduledRideViewModel.dropoffLocation) { _, newLocation in
                if let newLocation = newLocation, let pickup = scheduledRideViewModel.pickupLocation {
                    vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: newLocation)
                }
            }
        }
    }
    
    private func scheduleRide() {
        guard let pickup = scheduledRideViewModel.pickupLocation,
              let dropoff = scheduledRideViewModel.dropoffLocation,
              let vehicleType = vehicleViewModel.selectedVehicleType else {
            scheduledRideViewModel.errorMessage = "Veuillez sélectionner les adresses et le type de véhicule"
            return
        }
        
        Task {
            // Combiner date et heure
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledRideViewModel.selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledRideViewModel.selectedTime)
            var scheduledDateComponents = DateComponents()
            scheduledDateComponents.year = dateComponents.year
            scheduledDateComponents.month = dateComponents.month
            scheduledDateComponents.day = dateComponents.day
            scheduledDateComponents.hour = timeComponents.hour
            scheduledDateComponents.minute = timeComponents.minute
            
            guard let scheduledDate = calendar.date(from: scheduledDateComponents) else {
                await MainActor.run {
                    scheduledRideViewModel.errorMessage = "Date invalide"
                }
                return
            }
            
            // Créer la réservation programmée
            let success = await scheduledRideViewModel.createScheduledRide(
                pickupLocation: pickup,
                dropoffLocation: dropoff,
                scheduledDate: scheduledDate,
                vehicleType: vehicleType,
                paymentMethod: selectedPaymentMethod
            )
            
            if success {
                await MainActor.run {
                    showingSuccess = true
                }
            } else {
                await MainActor.run {
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    ScheduledRideView()
        .environmentObject(AuthViewModel())
}

