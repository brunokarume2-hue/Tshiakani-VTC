//
//  LocationPermissionScreen.swift
//  Tshiakani VTC
//
//  Écran de demande de permission de localisation
//

import SwiftUI
import CoreLocation

struct LocationPermissionScreen: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var navigateToPhoneInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icône de localisation
                Image(systemName: "location.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse)
                
                // Message principal
                VStack(spacing: 16) {
                    Text("onboarding.location.title".localized)
                        .font(AppTypography.title1())
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    Text("onboarding.location.message".localized)
                        .font(AppTypography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                
                // Statut de localisation
                HStack(spacing: 12) {
                    Image(systemName: locationStatusIcon)
                        .font(AppTypography.body())
                        .foregroundColor(locationStatusColor)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    
                    Text("Votre position : \(locationStatusText)")
                        .font(AppTypography.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
                
                Spacer()
                
                // Bouton principal avec espacement
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await requestLocationPermission()
                        }
                    }) {
                        Text("onboarding.location.button.continue".localized)
                            .font(AppTypography.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.primaryBlue)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .padding()
            .navigationBarHidden(true)
            .onChange(of: permissionManager.locationStatus) { _, newStatus in
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigateToPhoneInput = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToPhoneInput) {
                PhoneInputScreen()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
    
    private var locationStatusIcon: String {
        switch permissionManager.locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        case .denied, .restricted:
            return "xmark.circle.fill"
        default:
            return "location.slash"
        }
    }
    
    private var locationStatusColor: Color {
        switch permissionManager.locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return AppColors.success
        case .denied, .restricted:
            return AppColors.error
        default:
            return AppColors.warning
        }
    }
    
    private var locationStatusText: String {
        switch permissionManager.locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "onboarding.location.status.authorized".localized
        case .denied, .restricted:
            return "onboarding.location.status.denied".localized
        default:
            return "onboarding.location.status.none".localized
        }
    }
    
    private func requestLocationPermission() async {
        _ = await permissionManager.requestLocationPermission()
    }
}

#Preview {
    LocationPermissionScreen()
}

