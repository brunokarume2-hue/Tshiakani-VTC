//
//  VehicleSelectionView.swift
//  Tshiakani VTC
//
//  Vue de sélection de véhicule avec options Economy, Comfort, Business
//

import SwiftUI

struct VehicleSelectionView: View {
    let pickupLocation: Location?
    let dropoffLocation: Location?
    @Binding var selectedVehicle: VehicleType?
    @ObservedObject var vehicleViewModel: VehicleViewModel
    
    init(pickupLocation: Location?, dropoffLocation: Location?, selectedVehicle: Binding<VehicleType?>, vehicleViewModel: VehicleViewModel? = nil) {
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        _selectedVehicle = selectedVehicle
        if let viewModel = vehicleViewModel {
            _vehicleViewModel = ObservedObject(wrappedValue: viewModel)
        } else {
            _vehicleViewModel = ObservedObject(wrappedValue: VehicleViewModel(pickupLocation: pickupLocation, dropoffLocation: dropoffLocation))
        }
    }
    
    var body: some View {
        VStack(spacing: AppDesign.spacingS) {
            if vehicleViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentOrange))
                    .padding()
            } else {
                ForEach(vehicleViewModel.vehicleOptions) { option in
                    VehicleOptionCard(
                        option: option,
                        isSelected: selectedVehicle == option.type
                    ) {
                        vehicleViewModel.selectVehicle(option.type)
                        selectedVehicle = option.type
                    }
                }
            }
            
            if let errorMessage = vehicleViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            if let pickup = pickupLocation, let dropoff = dropoffLocation {
                vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: dropoff)
            }
        }
        .onChange(of: pickupLocation) { _, newLocation in
            if let pickup = newLocation, let dropoff = dropoffLocation {
                vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: dropoff)
            }
        }
        .onChange(of: dropoffLocation) { _, newLocation in
            if let pickup = pickupLocation, let dropoff = newLocation {
                vehicleViewModel.loadPriceEstimates(pickup: pickup, dropoff: dropoff)
            }
        }
        .onChange(of: vehicleViewModel.selectedVehicleType) { _, newType in
            selectedVehicle = newType
        }
    }
}

struct VehicleOptionCard: View {
    let option: VehicleOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(AppDesign.animationSnappy) {
                onSelect()
            }
        }) {
            cardContent
        }
        .buttonStyle(EnhancedButtonStyle())
        .animation(AppDesign.animationSnappy, value: isSelected)
        .accessibilityLabel(option.type.displayName)
        .accessibilityHint(isSelected ? "Sélectionné" : "Sélectionner ce type de véhicule")
        .accessibilityAddTraits(.isButton)
    }
    
    private var cardContent: some View {
        HStack(spacing: AppDesign.spacingM) {
            vehicleIcon
            
            vehicleInfo
            
            Spacer()
            
            priceInfo
        }
        .padding(.horizontal, AppDesign.spacingM)
        .padding(.vertical, AppDesign.spacingM)
        .background(cardBackground)
        .cornerRadius(AppDesign.cornerRadiusM)
        .overlay(cardBorder)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    private var vehicleIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusS)
                .fill(iconGradient)
                .frame(width: 40, height: 40)
            
            Image(systemName: option.type.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.accentOrange)
        }
        .shadow(color: iconShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var iconGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [AppColors.accentOrange.opacity(0.3), AppColors.accentOrange.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.accentOrange.opacity(0.15), AppColors.accentOrange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var iconShadowColor: Color {
        isSelected ? AppColors.accentOrange.opacity(0.3) : .clear
    }
    
    private var vehicleInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(option.type.displayName)
                .font(AppTypography.subheadline(weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.primaryText)
            
            Text(option.type.description)
                .font(AppTypography.caption())
                .foregroundColor(isSelected ? .white.opacity(0.9) : AppColors.secondaryText)
        }
    }
    
    private var priceInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let originalPrice = option.originalPrice {
                Text("\(Int(originalPrice)) FC")
                    .font(AppTypography.caption2())
                    .strikethrough()
                    .foregroundColor(isSelected ? .white.opacity(0.7) : AppColors.secondaryText)
            }
            
            Text("\(Int(option.price)) FC")
                .font(AppTypography.subheadline(weight: .bold))
                .foregroundColor(isSelected ? .white : AppColors.accentOrange)
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if isSelected {
            LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.clear
                .background(.thinMaterial)
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppDesign.cornerRadiusM)
            .stroke(
                isSelected ? Color.clear : AppColors.border.opacity(0.3),
                lineWidth: isSelected ? 0 : 1
            )
    }
    
    private var shadowColor: Color {
        isSelected ? .black.opacity(0.15) : .black.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        isSelected ? 8 : 2
    }
    
    private var shadowY: CGFloat {
        isSelected ? 4 : 1
    }
}

#Preview {
    VehicleSelectionView(
        pickupLocation: nil,
        dropoffLocation: nil,
        selectedVehicle: .constant(.economy)
    )
    .padding()
}

