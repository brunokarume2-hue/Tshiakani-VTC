//
//  BookingInputView.swift
//  Tshiakani VTC
//
//  Vue de saisie de l'itinéraire avec détection automatique de la position
//

import SwiftUI

struct BookingInputView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var bookingViewModel = BookingViewModel()
    @StateObject private var addressViewModel = AddressViewModel()
    @StateObject private var rideViewModel = RideViewModel()
    
    @State private var pickupAddress = ""
    @State private var dropoffAddress = ""
    @State private var showingPickupSearch = false
    @State private var showingDropoffSearch = false
    @State private var showingMapPicker = false
    @State private var isAutoDetecting = false
    @State private var navigateToMap = false
    @State private var showingError = false
    
    // Propriétés calculées depuis BookingViewModel
    private var pickupLocation: Location? {
        bookingViewModel.pickupLocation
    }
    
    private var dropoffLocation: Location? {
        bookingViewModel.dropoffLocation
    }
    
    private var estimatedPrice: Double {
        bookingViewModel.priceEstimate?.price ?? 0
    }
    
    private var estimatedDistance: Double {
        bookingViewModel.priceEstimate?.distance ?? 0
    }
    
    private var isEstimatingPrice: Bool {
        bookingViewModel.isLoading
    }
    
    var isFormValid: Bool {
        pickupLocation != nil && dropoffLocation != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.spacingXL) {
                    headerSection
                    pickupSection
                    dropoffSection
                    estimationSection
                    nextButton
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
                }
            }
            .sheet(isPresented: $showingPickupSearch) {
                pickupAddressSearchView
            }
            .sheet(isPresented: $showingDropoffSearch) {
                dropoffAddressSearchView
            }
            .sheet(isPresented: $showingMapPicker) {
                mapPickerView
            }
            .navigationDestination(isPresented: $navigateToMap) {
                rideMapDestination
            }
            .onAppear {
                autoDetectPickupLocation()
            }
            .onChange(of: bookingViewModel.pickupLocation) { _, _ in
                updatePickupAddress()
            }
            .onChange(of: bookingViewModel.dropoffLocation) { _, _ in
                updateDropoffAddress()
            }
            .onChange(of: bookingViewModel.errorMessage) { _, error in
                if let error = error {
                    showingError = true
                }
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(bookingViewModel.errorMessage ?? "Une erreur est survenue")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: AppDesign.spacingM) {
            // Illustration de carte avec pin (grande et centrée)
            ZStack {
                // Cercle de fond avec effet de profondeur
                Circle()
                    .fill(AppColors.accentOrange.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.accentOrange.opacity(0.2),
                                AppColors.accentOrange.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(AppColors.accentOrange)
            }
            .padding(.top, 40)
            
            Text("Choisissez votre itinéraire")
                .font(AppTypography.largeTitle(weight: .bold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Facilement")
                .font(AppTypography.largeTitle(weight: .bold))
                .foregroundColor(AppColors.accentOrange)
            
            Text("Indiquez votre point de départ et votre destination")
                .font(AppTypography.body())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.spacingL)
        }
        .padding(.top, 20)
        .padding(.horizontal, AppDesign.spacingM)
    }
    
    private var pickupSection: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingM) {
            HStack(spacing: AppDesign.spacingS) {
                ZStack {
                    Circle()
                        .fill(AppColors.success.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.success)
                }
                
                Text("Point de départ")
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            pickupAddressField
            useCurrentLocationButton
        }
        .padding(AppDesign.spacingM)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppDesign.cornerRadiusL)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, AppDesign.spacingM)
    }
    
    private var pickupAddressField: some View {
        Button(action: {
            HapticFeedback.light()
            showingPickupSearch = true
        }) {
            HStack(spacing: AppDesign.spacingM) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                
                Text(pickupAddress.isEmpty ? "Adresse de départ" : pickupAddress)
                    .font(AppTypography.body())
                    .foregroundColor(pickupAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                if !pickupAddress.isEmpty {
                    Button(action: {
                        HapticFeedback.selection()
                        bookingViewModel.pickupLocation = nil
                        pickupAddress = ""
                        Task {
                            await bookingViewModel.estimatePrice()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(AppDesign.spacingM)
            .frame(maxWidth: .infinity)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var useCurrentLocationButton: some View {
        Button(action: {
            HapticFeedback.selection()
            autoDetectPickupLocation()
        }) {
            HStack(spacing: AppDesign.spacingS) {
                if isAutoDetecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.success))
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.success)
                }
                
                Text("Utiliser ma position actuelle")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.success)
            }
            .frame(maxWidth: .infinity)
            .padding(AppDesign.spacingS)
        }
        .buttonStyle(.plain)
    }
    
    private var dropoffSection: some View {
        VStack(alignment: .leading, spacing: AppDesign.spacingM) {
            HStack(spacing: AppDesign.spacingS) {
                ZStack {
                    Circle()
                        .fill(AppColors.error.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.error)
                }
                
                Text("Destination")
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            dropoffAddressField
            chooseOnMapButton
        }
        .padding(AppDesign.spacingM)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppDesign.cornerRadiusL)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, AppDesign.spacingM)
    }
    
    private var dropoffAddressField: some View {
        Button(action: {
            HapticFeedback.light()
            showingDropoffSearch = true
        }) {
            HStack(spacing: AppDesign.spacingM) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                
                Text(dropoffAddress.isEmpty ? "Où allez-vous ?" : dropoffAddress)
                    .font(AppTypography.body())
                    .foregroundColor(dropoffAddress.isEmpty ? AppColors.secondaryText : AppColors.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                if !dropoffAddress.isEmpty {
                    Button(action: {
                        HapticFeedback.selection()
                        bookingViewModel.dropoffLocation = nil
                        dropoffAddress = ""
                        Task {
                            await bookingViewModel.estimatePrice()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(AppDesign.spacingM)
            .frame(maxWidth: .infinity)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppDesign.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var chooseOnMapButton: some View {
        Button(action: {
            HapticFeedback.selection()
            showingMapPicker = true
        }) {
            HStack(spacing: AppDesign.spacingS) {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.error)
                
                Text("Choisir sur la carte")
                    .font(AppTypography.subheadline(weight: .medium))
                    .foregroundColor(AppColors.error)
            }
            .frame(maxWidth: .infinity)
            .padding(AppDesign.spacingS)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var estimationSection: some View {
        if isFormValid {
            if isEstimatingPrice {
                loadingEstimateView
            } else if estimatedPrice > 0 {
                priceEstimateView
            }
        }
    }
    
    private var loadingEstimateView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                .scaleEffect(0.8)
            
            Text("Calcul de l'estimation...")
                .font(AppTypography.subheadline())
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(AppDesign.spacingM)
        .frame(maxWidth: .infinity)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppDesign.cornerRadiusM)
        .padding(.horizontal, AppDesign.spacingM)
    }
    
    private var priceEstimateView: some View {
        VStack(spacing: AppDesign.spacingM) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppColors.info)
                
                Text("Estimation")
                    .font(AppTypography.headline())
                    .foregroundColor(AppColors.primaryText)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(String(format: "%.1f km", estimatedDistance))
                        .font(AppTypography.subheadline(weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Prix estimé")
                        .font(AppTypography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(Int(estimatedPrice)) FC")
                        .font(AppTypography.title3(weight: .bold))
                        .foregroundColor(AppColors.accentOrange)
                }
            }
        }
        .padding(AppDesign.spacingM)
        .background(AppColors.accentOrangeLight)
        .cornerRadius(AppDesign.cornerRadiusM)
        .padding(.horizontal, AppDesign.spacingM)
    }
    
    private var nextButton: some View {
        Button(action: {
            guard isFormValid else { return }
            HapticFeedback.medium()
            navigateToMap = true
        }) {
            HStack {
                Text("Suivant")
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(
            LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(AppDesign.cornerRadiusL)
        .buttonShadow()
        .padding(.horizontal, AppDesign.spacingM)
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    private var pickupAddressSearchView: some View {
        AddressSearchView(
            selectedLocation: Binding(
                get: { bookingViewModel.pickupLocation },
                set: { location in
                    if let location = location {
                        bookingViewModel.setPickupLocation(location)
                        pickupAddress = location.address ?? "\(location.latitude), \(location.longitude)"
                        Task {
                            await bookingViewModel.estimatePrice()
                        }
                    }
                }
            ),
            address: $pickupAddress
        )
    }
    
    private var dropoffAddressSearchView: some View {
        AddressSearchView(
            selectedLocation: Binding(
                get: { bookingViewModel.dropoffLocation },
                set: { location in
                    if let location = location {
                        bookingViewModel.setDropoffLocation(location)
                        dropoffAddress = location.address ?? "\(location.latitude), \(location.longitude)"
                        Task {
                            await bookingViewModel.estimatePrice()
                        }
                    }
                }
            ),
            address: $dropoffAddress
        )
    }
    
    private var mapPickerView: some View {
        MapLocationPickerView(
            selectedLocation: Binding(
                get: { bookingViewModel.dropoffLocation },
                set: { location in
                    if let location = location {
                        bookingViewModel.setDropoffLocation(location)
                        dropoffAddress = location.address ?? "\(location.latitude), \(location.longitude)"
                        Task {
                            await bookingViewModel.estimatePrice()
                        }
                    }
                }
            ),
            address: $dropoffAddress
        )
    }
    
    @ViewBuilder
    private var rideMapDestination: some View {
        if let pickup = bookingViewModel.pickupLocation, let dropoff = bookingViewModel.dropoffLocation {
            RideMapView(
                pickupLocation: pickup,
                dropoffLocation: dropoff,
                estimatedPrice: estimatedPrice,
                estimatedDistance: estimatedDistance
            )
            .environmentObject(authViewModel)
            .environmentObject(bookingViewModel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updatePickupAddress() {
        if let location = bookingViewModel.pickupLocation {
            pickupAddress = location.address ?? "\(location.latitude), \(location.longitude)"
            Task {
                await bookingViewModel.estimatePrice()
            }
        }
    }
    
    private func updateDropoffAddress() {
        if let location = bookingViewModel.dropoffLocation {
            dropoffAddress = location.address ?? "\(location.latitude), \(location.longitude)"
            Task {
                await bookingViewModel.estimatePrice()
            }
        }
    }
    
    private func autoDetectPickupLocation() {
        isAutoDetecting = true
        
        // Si on a déjà une position actuelle, l'utiliser
        if let current = locationManager.currentLocation {
            bookingViewModel.setPickupLocation(current)
            pickupAddress = current.address ?? "Position actuelle"
            isAutoDetecting = false
            Task {
                await bookingViewModel.estimatePrice()
            }
            return
        }
        
        // Sinon, démarrer la mise à jour de la localisation
        if !locationManager.isAuthorized {
            locationManager.requestAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        
        // Attendre la localisation
        Task {
            var attempts = 0
            while attempts < 10 && bookingViewModel.pickupLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
                
                if let current = locationManager.currentLocation {
                    await MainActor.run {
                        bookingViewModel.setPickupLocation(current)
                        pickupAddress = current.address ?? "Position actuelle"
                        isAutoDetecting = false
                    }
                    await bookingViewModel.estimatePrice()
                    return
                }
                attempts += 1
            }
            
            await MainActor.run {
                isAutoDetecting = false
            }
        }
    }
}

#Preview {
    BookingInputView()
        .environmentObject(AuthViewModel())
}

