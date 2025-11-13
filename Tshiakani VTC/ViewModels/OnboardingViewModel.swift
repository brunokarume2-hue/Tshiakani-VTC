//
//  OnboardingViewModel.swift
//  Tshiakani VTC
//
//  ViewModel pour gérer le flux d'onboarding
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import UserNotifications

class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .splash
    @Published var phoneNumber: String = ""
    @Published var isValidPhone: Bool = false
    @Published var verificationCode: String = ""
    @Published var isCodeVerified: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedRole: UserRole = .client
    
    // Permissions
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isLocationAuthorized: Bool = false
    @Published var isNotificationAuthorized: Bool = false
    
    // OTP
    @Published var otpSent: Bool = false
    @Published var otpExpiresIn: Int = 0
    @Published var canResendOTP: Bool = false
    @Published var resendTimer: Int = 60
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let authViewModel = AuthViewModel()
    private let authManager = AuthManager()
    private let permissionManager = PermissionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var resendTimerTask: Task<Void, Never>?
    
    // MARK: - Enums
    
    enum OnboardingStep {
        case splash
        case onboarding
        case locationPermission
        case phoneInput
        case codeVerification
        case accountSelection
        case completed
    }
    
    // MARK: - Initialization
    
    init() {
        checkPermissions()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observer les changements de permission de localisation
        permissionManager.$locationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.locationPermissionStatus, on: self)
            .store(in: &cancellables)
        
        permissionManager.$isLocationAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLocationAuthorized, on: self)
            .store(in: &cancellables)
        
        // Observer les changements de permission de notifications
        permissionManager.$notificationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.notificationPermissionStatus, on: self)
            .store(in: &cancellables)
        
        permissionManager.$isNotificationAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: \.isNotificationAuthorized, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        switch currentStep {
        case .splash:
            currentStep = .onboarding
        case .onboarding:
            currentStep = .locationPermission
        case .locationPermission:
            if isLocationAuthorized {
                currentStep = .phoneInput
            }
        case .phoneInput:
            if isValidPhone {
                currentStep = .codeVerification
            }
        case .codeVerification:
            if isCodeVerified {
                currentStep = .accountSelection
            }
        case .accountSelection:
            currentStep = .completed
        case .completed:
            break
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .splash:
            break
        case .onboarding:
            currentStep = .splash
        case .locationPermission:
            currentStep = .onboarding
        case .phoneInput:
            currentStep = .locationPermission
        case .codeVerification:
            currentStep = .phoneInput
        case .accountSelection:
            currentStep = .codeVerification
        case .completed:
            break
        }
    }
    
    // MARK: - Phone Number Validation
    
    func validatePhoneNumber(_ number: String) {
        phoneNumber = number
        // Format congolais: 9 chiffres après +243
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Validation: 9 chiffres
        isValidPhone = cleaned.count == 9 && cleaned.allSatisfy { $0.isNumber }
    }
    
    func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count <= 9 else { return phoneNumber }
        
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 3 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }
    
    // MARK: - Permissions
    
    func checkPermissions() {
        permissionManager.checkAllPermissions()
        locationPermissionStatus = permissionManager.locationStatus
        isLocationAuthorized = permissionManager.isLocationAuthorized
        notificationPermissionStatus = permissionManager.notificationStatus
        isNotificationAuthorized = permissionManager.isNotificationAuthorized
    }
    
    func requestLocationPermission() async {
        let granted = await permissionManager.requestLocationPermission()
        await MainActor.run {
            isLocationAuthorized = granted
            locationPermissionStatus = granted ? .authorizedWhenInUse : .denied
        }
    }
    
    func requestNotificationPermission() async {
        let granted = await permissionManager.requestNotificationPermission()
        await MainActor.run {
            isNotificationAuthorized = granted
            notificationPermissionStatus = granted ? .authorized : .denied
        }
    }
    
    func openLocationSettings() {
        permissionManager.openLocationSettings()
    }
    
    func openNotificationSettings() {
        permissionManager.openNotificationSettings()
    }
    
    // MARK: - OTP
    
    func sendOTP() async {
        guard isValidPhone else {
            await MainActor.run {
                errorMessage = "Numéro de téléphone invalide"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
        
        do {
            let result = try await apiService.sendOTP(phoneNumber: fullPhoneNumber, channel: "whatsapp")
            
            await MainActor.run {
                otpSent = true
                otpExpiresIn = result.expiresIn
                isLoading = false
                startResendTimer()
            }
            
            print("✅ OTP envoyé - Expires in: \(result.expiresIn) secondes")
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'envoi du code: \(error.localizedDescription)"
                isLoading = false
                otpSent = false
            }
            print("❌ Erreur sendOTP: \(error)")
        }
    }
    
    func verifyOTP() async {
        guard verificationCode.count == 6 else {
            await MainActor.run {
                errorMessage = "Le code doit contenir 6 chiffres"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let fullPhoneNumber = "+243\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
        
        do {
            await authViewModel.verifyOTP(
                phoneNumber: fullPhoneNumber,
                code: verificationCode,
                role: selectedRole,
                userName: nil
            )
            
            await MainActor.run {
                isCodeVerified = authViewModel.isAuthenticated
                isLoading = false
                
                if isCodeVerified {
                    // Marquer l'onboarding comme terminé
                    authManager.hasSeenOnboarding = true
                } else {
                    errorMessage = authViewModel.errorMessage ?? "Code invalide"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la vérification: \(error.localizedDescription)"
                isLoading = false
                isCodeVerified = false
            }
            print("❌ Erreur verifyOTP: \(error)")
        }
    }
    
    func resendOTP() async {
        canResendOTP = false
        resendTimer = 60
        await sendOTP()
    }
    
    private func startResendTimer() {
        resendTimerTask?.cancel()
        resendTimer = 60
        canResendOTP = false
        
        resendTimerTask = Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                
                if Task.isCancelled {
                    return
                }
                
                await MainActor.run {
                    resendTimer -= 1
                    if resendTimer <= 0 {
                        canResendOTP = true
                        resendTimerTask?.cancel()
                    }
                }
            }
        }
    }
    
    // MARK: - Account Selection
    
    func selectRole(_ role: UserRole) {
        selectedRole = role
    }
    
    func completeOnboarding() {
        authManager.hasSeenOnboarding = true
        currentStep = .completed
    }
    
    // MARK: - Cleanup
    
    deinit {
        resendTimerTask?.cancel()
        cancellables.removeAll()
    }
}

