//
//  FrontendAgentPrincipal.swift
//  Tshiakani VTC
//
//  Agent Principal Frontend - Orchestrateur central de toutes les opérations
//  Coordonne les services, gère les transactions, optimise les performances
//

import Foundation
import Combine
import SwiftUI
import CoreLocation

/**
 * Agent Principal Frontend
 * Orchestrateur central pour toutes les opérations du frontend iOS
 */
class FrontendAgentPrincipal: ObservableObject {
    static let shared = FrontendAgentPrincipal()
    
    // MARK: - Services
    
    private let apiService = APIService.shared
    private let locationService = LocationService.shared
    private let realtimeService = RealtimeService.shared
    private let notificationService = NotificationService.shared
    private let paymentService = PaymentService.shared
    private let localStorage = LocalStorageService.shared
    private let config = ConfigurationService.shared
    private let addressSearchService = AddressSearchService.shared
    // Services Google optionnels (peuvent ne pas être utilisés dans toutes les configurations)
    // private let googlePlacesService = GooglePlacesService.shared
    // private let googleMapsService = GoogleMapsService.shared
    // private let googleDirectionsService = GoogleDirectionsService.shared
    
    // MARK: - État
    
    @Published var currentUser: User?
    @Published var currentRide: Ride?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableDrivers: [User] = []
    @Published var rideHistory: [Ride] = []
    
    // Exposer la localisation actuelle pour un accès facile
    var currentLocation: Location? {
        get {
            locationService.currentLocation
        }
    }
    
    // Exposer le statut d'autorisation de localisation
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    // MARK: - Propriétés internes
    
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateTimer: Timer?
    private var driverTrackingTimer: Timer?
    private var currentUserId: String?
    private var currentUserRole: UserRole?
    
    // MARK: - Callbacks
    
    var onRideStatusChanged: ((Ride) -> Void)?
    var onDriverLocationUpdated: ((Location) -> Void)?
    var onRideAccepted: ((Ride, User) -> Void)?
    var onRideCompleted: ((Ride) -> Void)?
    var onRideCancelled: ((Ride) -> Void)?
    var onError: ((Error) -> Void)?
    
    private init() {
        setupObservers()
        loadCachedUser()
    }
    
    // MARK: - Configuration
    
    private func setupObservers() {
        // Observer l'état de connexion temps réel
        realtimeService.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.setupRealtimeListeners()
                }
            }
            .store(in: &cancellables)
        
        // Observer les changements de localisation
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }
    
    private func setupRealtimeListeners() {
        // Écouter les changements de statut de course
        realtimeService.onRideStatusChanged = { [weak self] ride in
            DispatchQueue.main.async {
                self?.handleRideStatusChanged(ride)
            }
        }
        
        // Écouter les acceptations de course
        realtimeService.onRideAccepted = { [weak self] ride in
            DispatchQueue.main.async {
                self?.handleRideAccepted(ride)
            }
        }
        
        // Écouter les annulations
        realtimeService.onRideCancelled = { [weak self] rideId in
            DispatchQueue.main.async {
                self?.handleRideCancelled(rideId)
            }
        }
        
        // Écouter les mises à jour de position du conducteur
        realtimeService.onDriverLocationUpdated = { [weak self] ride, location in
            DispatchQueue.main.async {
                if let driverId = ride.driverId {
                    self?.handleDriverLocationUpdate(driverId: driverId, location: location)
                }
            }
        }
    }
    
    // MARK: - Authentification
    
    /**
     * Authentifie un utilisateur
     * @param phoneNumber - Numéro de téléphone
     * @param role - Rôle de l'utilisateur (client, driver, admin)
     * @param name - Nom de l'utilisateur (optionnel)
     * @returns Utilisateur authentifié
     */
    func authenticate(phoneNumber: String, role: UserRole, name: String? = nil) async throws -> User {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Authentifier via l'API
            let (token, user) = try await apiService.signIn(phoneNumber: phoneNumber, role: role, name: name)
            
            // Sauvegarder le token
            config.setAuthToken(token)
            
            // Sauvegarder l'utilisateur en cache
            await saveUserToCache(user)
            
            // Mettre à jour l'état
            await MainActor.run {
                currentUser = user
                currentUserId = user.id
                currentUserRole = user.role
                isAuthenticated = true
                isLoading = false
            }
            
            // Se connecter au service temps réel
            realtimeService.connect(userId: user.id, userRole: user.role)
            
            // Charger les données utilisateur
            await loadUserData(userId: user.id)
            
            return user
        } catch {
            await MainActor.run {
                errorMessage = "Erreur d'authentification: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    /**
     * Déconnecte l'utilisateur actuel
     */
    func logout() {
        // Arrêter les timers
        stopLocationUpdates()
        stopDriverTracking()
        
        // Déconnecter du service temps réel
        realtimeService.disconnect()
        
        // Nettoyer l'état
        currentUser = nil
        currentUserId = nil
        currentUserRole = nil
        isAuthenticated = false
        currentRide = nil
        availableDrivers = []
        rideHistory = []
        
        // Supprimer le token
        config.setAuthToken(nil)
        
        // Supprimer le cache utilisateur
        localStorage.remove(key: "cached_user")
    }
    
    /**
     * Met à jour le profil utilisateur
     * @param name - Nouveau nom
     * @returns Utilisateur mis à jour
     */
    func updateProfile(name: String) async throws -> User {
        guard let userId = currentUserId else {
            throw NSError(domain: "FrontendAgentPrincipal", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let updatedUser = try await apiService.updateProfile(name: name)
            
            await MainActor.run {
                currentUser = updatedUser
                isLoading = false
            }
            
            // Sauvegarder en cache
            await saveUserToCache(updatedUser)
            
            return updatedUser
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour du profil: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    // MARK: - Gestion des Courses
    
    /**
     * Crée une nouvelle course avec pricing automatique et matching
     * @param pickupLocation - Localisation de départ
     * @param dropoffLocation - Localisation d'arrivée
     * @param paymentMethod - Méthode de paiement (optionnel)
     * @returns Course créée avec pricing et matching
     */
    func createRide(pickupLocation: Location, dropoffLocation: Location, paymentMethod: PaymentMethod? = nil) async throws -> Ride {
        guard let userId = currentUserId else {
            throw NSError(domain: "FrontendAgentPrincipal", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Vérifier que les adresses sont définies
            var pickup = pickupLocation
            var dropoff = dropoffLocation
            
            // Si l'adresse n'est pas définie, la récupérer via géocodage inverse
            if pickup.address == nil {
                pickup = await getAddress(for: pickup)
            }
            
            if dropoff.address == nil {
                dropoff = await getAddress(for: dropoff)
            }
            
            // 2. Calculer la distance
            let distance = pickup.distance(to: dropoff)
            
            // 3. Estimer le prix (le backend le recalculera avec IA)
            let priceEstimate = try await apiService.estimatePrice(
                pickup: pickup,
                dropoff: dropoff,
                distance: distance
            )
            
            // 4. Créer la course
            let ride = Ride(
                clientId: userId,
                pickupLocation: pickup,
                dropoffLocation: dropoff,
                status: .pending,
                estimatedPrice: priceEstimate.price,
                paymentMethod: paymentMethod,
                distance: distance
            )
            
            // 5. Créer la course via l'API (le backend fait le matching automatique)
            let createdRide = try await apiService.createRide(ride)
            
            // 6. Mettre à jour l'état
            await MainActor.run {
                currentRide = createdRide
                isLoading = false
            }
            
            // 7. Envoyer la demande via le service temps réel
            try await realtimeService.sendRideRequest(createdRide)
            
            // 8. Démarrer le suivi du conducteur si la course est acceptée
            if createdRide.status == .accepted, let driverId = createdRide.driverId {
                startDriverTracking(rideId: createdRide.id, driverId: driverId)
            }
            
            // 9. Notifier
            onRideStatusChanged?(createdRide)
            
            return createdRide
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création de la course: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    /**
     * Annule une course
     * @param rideId - ID de la course (optionnel, utilise currentRide si nil)
     * @returns Course annulée
     */
    func cancelRide(rideId: String? = nil) async throws -> Ride {
        let rideIdToCancel = rideId ?? currentRide?.id
        
        guard let rideIdToCancel = rideIdToCancel else {
            throw NSError(domain: "FrontendAgentPrincipal", code: 400, userInfo: [NSLocalizedDescriptionKey: "Aucune course à annuler"])
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Annuler via l'API
            let cancelledRide = try await apiService.updateRideStatus(rideIdToCancel, status: .cancelled)
            
            // Annuler via le service temps réel
            try await realtimeService.cancelRide(rideIdToCancel)
            
            // Arrêter le suivi du conducteur
            stopDriverTracking()
            
            // Mettre à jour l'état
            await MainActor.run {
                if currentRide?.id == rideIdToCancel {
                    currentRide = cancelledRide
                }
                isLoading = false
            }
            
            // Notifier
            onRideCancelled?(cancelledRide)
            onRideStatusChanged?(cancelledRide)
            
            // Nettoyer la course actuelle après un délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if self?.currentRide?.id == rideIdToCancel {
                    self?.currentRide = nil
                }
            }
            
            return cancelledRide
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'annulation: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    /**
     * Met à jour le statut d'une course
     * @param rideId - ID de la course
     * @param status - Nouveau statut
     * @returns Course mise à jour
     */
    func updateRideStatus(rideId: String, status: RideStatus) async throws -> Ride {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Mettre à jour via l'API
            let updatedRide = try await apiService.updateRideStatus(rideId, status: status)
            
            // Mettre à jour via le service temps réel
            try await realtimeService.updateRideStatus(rideId: rideId, status: status)
            
            // Mettre à jour l'état
            await MainActor.run {
                if currentRide?.id == rideId {
                    currentRide = updatedRide
                }
                isLoading = false
            }
            
            // Gérer les événements spécifiques
            switch status {
            case .completed:
                onRideCompleted?(updatedRide)
                stopDriverTracking()
            case .cancelled:
                onRideCancelled?(updatedRide)
                stopDriverTracking()
            default:
                break
            }
            
            // Notifier
            onRideStatusChanged?(updatedRide)
            
            return updatedRide
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la mise à jour du statut: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    /**
     * Évalue une course
     * @param rideId - ID de la course
     * @param rating - Note de 1 à 5
     * @param comment - Commentaire (optionnel)
     * @param tip - Pourboire (optionnel)
     */
    func rateRide(rideId: String, rating: Int, comment: String? = nil, tip: Double? = nil) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await apiService.rateRide(rideId, rating: rating, comment: comment, tip: tip)
            
            // Mettre à jour la course locale
            if let index = rideHistory.firstIndex(where: { $0.id == rideId }) {
                var updatedRide = rideHistory[index]
                updatedRide.rating = rating
                updatedRide.review = comment
                rideHistory[index] = updatedRide
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'évaluation: \(error.localizedDescription)"
                isLoading = false
            }
            onError?(error)
            throw error
        }
    }
    
    // MARK: - Gestion de la Localisation
    
    /**
     * Demande l'autorisation de localisation
     */
    func requestLocationPermission() {
        locationService.requestAuthorization()
    }
    
    /**
     * Démarre la mise à jour de la localisation
     */
    func startLocationUpdates() {
        locationService.startUpdatingLocation()
        
        // Créer un timer pour mettre à jour périodiquement
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.locationService.startUpdatingLocation()
        }
    }
    
    /**
     * Arrête la mise à jour de la localisation
     */
    func stopLocationUpdates() {
        locationService.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    /**
     * Recherche des adresses avec AddressSearchService (utilise MKLocalSearch)
     * @param query - Requête de recherche
     * @returns Liste d'adresses
     */
    func searchAddresses(query: String) async throws -> [Location] {
        guard !query.isEmpty else {
            return []
        }
        
        // Utiliser AddressSearchService qui utilise MKLocalSearch
        addressSearchService.search(query: query)
        
        // Attendre un délai raisonnable pour que les résultats arrivent
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
        
        // Convertir les résultats MKLocalSearchCompletion en Location
        var locations: [Location] = []
        let completions = addressSearchService.searchResults.prefix(10) // Limiter à 10 résultats
        
        for completion in completions {
            do {
                let location = try await addressSearchService.getLocation(from: completion)
                locations.append(location)
            } catch {
                // Ignorer les erreurs pour une completion individuelle
                continue
            }
        }
        
        return locations
    }
    
    /**
     * Obtient l'adresse d'une localisation (géocodage inverse)
     * @param location - Localisation
     * @returns Location avec l'adresse mise à jour
     */
    private func getAddress(for location: Location) async -> Location {
        return await withCheckedContinuation { continuation in
            locationService.getAddress(from: location) { address in
                var updatedLocation = location
                updatedLocation.address = address
                continuation.resume(returning: updatedLocation)
            }
        }
    }
    
    // MARK: - Suivi du Conducteur
    
    /**
     * Démarre le suivi de la position du conducteur
     * @param rideId - ID de la course
     * @param driverId - ID du conducteur
     */
    private func startDriverTracking(rideId: String, driverId: String) {
        stopDriverTracking()
        
        driverTrackingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateDriverLocation(rideId: rideId, driverId: driverId)
            }
        }
    }
    
    /**
     * Arrête le suivi du conducteur
     */
    private func stopDriverTracking() {
        driverTrackingTimer?.invalidate()
        driverTrackingTimer = nil
    }
    
    /**
     * Met à jour la position du conducteur
     * @param rideId - ID de la course
     * @param driverId - ID du conducteur
     */
    private func updateDriverLocation(rideId: String, driverId: String) async {
        do {
            let (_, _, location, _, _) = try await apiService.trackDriver(rideId: rideId)
            
            await MainActor.run {
                // Mettre à jour la course actuelle
                if let ride = currentRide, ride.id == rideId {
                    // Créer une nouvelle instance de Ride avec la position du conducteur mise à jour
                    var updatedRide = ride
                    updatedRide.driverLocation = location
                    currentRide = updatedRide
                    
                    // Notifier
                    onDriverLocationUpdated?(location)
                }
            }
        } catch {
            print("Erreur lors de la mise à jour de la position du conducteur: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recherche de Conducteurs
    
    /**
     * Trouve les conducteurs disponibles près d'une localisation
     * @param location - Localisation
     * @param radius - Rayon de recherche en km (défaut: 5.0)
     */
    func findAvailableDrivers(near location: Location, radius: Double = 5.0) async {
        do {
            let drivers = try await apiService.getAvailableDrivers(
                latitude: location.latitude,
                longitude: location.longitude,
                radius: radius
            )
            
            await MainActor.run {
                availableDrivers = drivers
            }
        } catch {
            print("Erreur lors de la recherche de conducteurs: \(error.localizedDescription)")
            await MainActor.run {
                availableDrivers = []
            }
        }
    }
    
    // MARK: - Historique des Courses
    
    /**
     * Charge l'historique des courses
     * @param userId - ID de l'utilisateur (optionnel, utilise currentUserId si nil)
     */
    func loadRideHistory(userId: String? = nil) async {
        let userIdToUse = userId ?? currentUserId
        
        guard let userIdToUse = userIdToUse else {
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let history = try await apiService.getRideHistory(for: userIdToUse)
            
            await MainActor.run {
                rideHistory = history
                isLoading = false
            }
        } catch {
            print("Erreur lors du chargement de l'historique: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // MARK: - Gestion des Données Utilisateur
    
    /**
     * Charge les données utilisateur
     * @param userId - ID de l'utilisateur
     */
    private func loadUserData(userId: String) async {
        // Charger l'historique des courses
        await loadRideHistory(userId: userId)
        
        // Charger les courses actives
        await realtimeService.loadActiveRides(userId: userId, userRole: currentUserRole ?? .client)
        
        // Mettre à jour la course actuelle si une course active existe
        if let activeRide = realtimeService.activeRides.first {
            await MainActor.run {
                currentRide = activeRide
                
                // Démarrer le suivi si la course est acceptée
                if activeRide.status == .accepted, let driverId = activeRide.driverId {
                    self.startDriverTracking(rideId: activeRide.id, driverId: driverId)
                }
            }
        }
    }
    
    /**
     * Charge l'utilisateur depuis le cache
     */
    private func loadCachedUser() {
        if let userData = localStorage.get(key: "cached_user") as? Data,
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            currentUserId = user.id
            currentUserRole = user.role
            isAuthenticated = config.getAuthToken() != nil
            
            // Se connecter au service temps réel si authentifié
            if isAuthenticated {
                realtimeService.connect(userId: user.id, userRole: user.role)
            }
        }
    }
    
    /**
     * Sauvegarde l'utilisateur dans le cache
     * @param user - Utilisateur à sauvegarder
     */
    private func saveUserToCache(_ user: User) async {
        if let userData = try? JSONEncoder().encode(user) {
            localStorage.set(key: "cached_user", value: userData)
        }
    }
    
    // MARK: - Gestion des Événements
    
    /**
     * Gère les changements de statut de course
     * @param ride - Course mise à jour
     */
    private func handleRideStatusChanged(_ ride: Ride) {
        // Mettre à jour la course actuelle
        if currentRide?.id == ride.id {
            currentRide = ride
            
            // Gérer les événements spécifiques
            switch ride.status {
            case .accepted:
                if let driverId = ride.driverId {
                    startDriverTracking(rideId: ride.id, driverId: driverId)
                }
            case .completed, .cancelled:
                stopDriverTracking()
            default:
                break
            }
        }
        
        // Mettre à jour l'historique
        if let index = rideHistory.firstIndex(where: { $0.id == ride.id }) {
            rideHistory[index] = ride
        } else if ride.status == .completed || ride.status == .cancelled {
            rideHistory.insert(ride, at: 0)
        }
        
        // Notifier
        onRideStatusChanged?(ride)
    }
    
    /**
     * Gère l'acceptation d'une course
     * @param ride - Course acceptée
     */
    private func handleRideAccepted(_ ride: Ride) {
        // Charger les informations du conducteur
        if let driverId = ride.driverId {
            Task {
                do {
                    let driver = try await apiService.getUser(id: driverId)
                    await MainActor.run {
                        onRideAccepted?(ride, driver)
                    }
                } catch {
                    print("Erreur lors du chargement du conducteur: \(error.localizedDescription)")
                }
            }
        }
        
        handleRideStatusChanged(ride)
    }
    
    /**
     * Gère l'annulation d'une course
     * @param rideId - ID de la course annulée
     */
    private func handleRideCancelled(_ rideId: String) {
        stopDriverTracking()
        
        if let ride = currentRide, ride.id == rideId {
            onRideCancelled?(ride)
            currentRide = nil
        }
    }
    
    /**
     * Gère les mises à jour de localisation du conducteur
     * @param driverId - ID du conducteur
     * @param location - Nouvelle localisation
     */
    private func handleDriverLocationUpdate(driverId: String, location: Location) {
        if let ride = currentRide, ride.driverId == driverId {
            // Créer une nouvelle instance de Ride avec la position du conducteur mise à jour
            var updatedRide = ride
            updatedRide.driverLocation = location
            currentRide = updatedRide
            onDriverLocationUpdated?(location)
        }
    }
    
    /**
     * Gère les mises à jour de localisation de l'utilisateur
     * @param location - Nouvelle localisation
     */
    private func handleLocationUpdate(_ location: Location) {
        // Si une course est en cours, on peut mettre à jour la position du client
        // (utile pour le suivi en temps réel)
    }
    
    // MARK: - Utilitaires
    
    /**
     * Calcule la distance entre deux points
     * @param from - Point de départ
     * @param to - Point d'arrivée
     * @returns Distance en kilomètres
     */
    func calculateDistance(from: Location, to: Location) -> Double {
        return from.distance(to: to)
    }
    
    /**
     * Obtient les directions entre deux points
     * @param from - Point de départ
     * @param to - Point d'arrivée
     * @returns Directions (liste de points de l'itinéraire)
     */
    func getDirections(from: Location, to: Location) async throws -> [Location] {
        // Utiliser GoogleDirectionsService si disponible, sinon utiliser LocationService
        // Pour l'instant, retourner une liste simple avec les deux points
        // TODO: Implémenter le calcul d'itinéraire complet avec GoogleDirectionsService
        // Note: Cette méthode peut être étendue pour utiliser GoogleDirectionsService.shared.calculateRoute()
        return [from, to]
    }
    
    /**
     * Nettoie les ressources
     */
    deinit {
        stopLocationUpdates()
        stopDriverTracking()
        cancellables.removeAll()
    }
}

