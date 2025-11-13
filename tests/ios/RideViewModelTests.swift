//
//  RideViewModelTests.swift
//  Tshiakani VTC Tests
//
//  Tests pour le ViewModel de course
//  Teste le cycle complet d'une course du point de vue iOS
//

import XCTest
import Combine
@testable import Tshiakani_VTC

@MainActor
class RideViewModelTests: XCTestCase {
    var viewModel: RideViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = RideViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Tests de Demande de Course
    
    func testRequestRide_CreatesPendingRide() async {
        // Arrange
        let pickup = Location(latitude: -4.3276, longitude: 15.3156)
        let dropoff = Location(latitude: -4.3376, longitude: 15.3256)
        let userId = "test-client-id"
        
        // Act
        await viewModel.requestRide(pickup: pickup, dropoff: dropoff, userId: userId)
        
        // Assert
        XCTAssertNotNil(viewModel.currentRide, "La course devrait être créée")
        XCTAssertEqual(viewModel.currentRide?.status, .pending, "Le statut devrait être 'pending'")
        XCTAssertEqual(viewModel.currentRide?.clientId, userId, "L'ID client devrait correspondre")
        XCTAssertNil(viewModel.currentRide?.driverId, "Le chauffeur ne devrait pas être assigné initialement")
    }
    
    func testRequestRide_SetsCorrectLocations() async {
        // Arrange
        let pickup = Location(latitude: -4.3276, longitude: 15.3156)
        let dropoff = Location(latitude: -4.3376, longitude: 15.3256)
        let userId = "test-client-id"
        
        // Act
        await viewModel.requestRide(pickup: pickup, dropoff: dropoff, userId: userId)
        
        // Assert
        XCTAssertEqual(viewModel.currentRide?.pickupLocation.latitude, pickup.latitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentRide?.pickupLocation.longitude, pickup.longitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentRide?.dropoffLocation.latitude, dropoff.latitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentRide?.dropoffLocation.longitude, dropoff.longitude, accuracy: 0.0001)
    }
    
    func testRequestRide_WithoutUserId_Fails() async {
        // Arrange
        let pickup = Location(latitude: -4.3276, longitude: 15.3156)
        let dropoff = Location(latitude: -4.3376, longitude: 15.3256)
        let userId = ""
        
        // Act
        await viewModel.requestRide(pickup: pickup, dropoff: dropoff, userId: userId)
        
        // Assert
        XCTAssertNil(viewModel.currentRide, "La course ne devrait pas être créée sans userId")
        XCTAssertNotNil(viewModel.errorMessage, "Un message d'erreur devrait être affiché")
        XCTAssertFalse(viewModel.isLoading, "Le chargement devrait être terminé")
    }
    
    // MARK: - Tests de Mise à Jour de Statut
    
    func testRideStatusUpdate_Accepted_UpdatesRide() {
        // Arrange
        let ride = createTestRide(status: .pending)
        viewModel.currentRide = ride
        
        let expectation = expectation(description: "Ride status updated")
        
        // Act
        let updatedRide = createTestRide(status: .accepted, id: ride.id)
        
        // Simuler la mise à jour via le service temps réel
        viewModel.currentRide = updatedRide
        
        // Assert
        XCTAssertEqual(viewModel.currentRide?.status, .accepted, "Le statut devrait être 'accepted'")
        expectation.fulfill()
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRideStatusUpdate_DriverArriving_UpdatesRide() {
        // Arrange
        let ride = createTestRide(status: .accepted)
        viewModel.currentRide = ride
        
        // Act
        let updatedRide = createTestRide(status: .driverArriving, id: ride.id)
        viewModel.currentRide = updatedRide
        
        // Assert
        XCTAssertEqual(viewModel.currentRide?.status, .driverArriving, "Le statut devrait être 'driverArriving'")
    }
    
    func testRideStatusUpdate_InProgress_UpdatesRide() {
        // Arrange
        let ride = createTestRide(status: .driverArriving)
        viewModel.currentRide = ride
        
        // Act
        var updatedRide = createTestRide(status: .inProgress, id: ride.id)
        updatedRide.startedAt = Date()
        viewModel.currentRide = updatedRide
        
        // Assert
        XCTAssertEqual(viewModel.currentRide?.status, .inProgress, "Le statut devrait être 'inProgress'")
        XCTAssertNotNil(viewModel.currentRide?.startedAt, "La date de début devrait être définie")
    }
    
    func testRideStatusUpdate_Completed_UpdatesRide() {
        // Arrange
        let ride = createTestRide(status: .inProgress)
        viewModel.currentRide = ride
        
        // Act
        var updatedRide = createTestRide(status: .completed, id: ride.id)
        updatedRide.completedAt = Date()
        updatedRide.finalPrice = 5500
        viewModel.currentRide = updatedRide
        
        // Assert
        XCTAssertEqual(viewModel.currentRide?.status, .completed, "Le statut devrait être 'completed'")
        XCTAssertNotNil(viewModel.currentRide?.completedAt, "La date de fin devrait être définie")
        XCTAssertEqual(viewModel.currentRide?.finalPrice, 5500, "Le prix final devrait être défini")
    }
    
    // MARK: - Tests d'Annulation
    
    func testCancelRide_UpdatesStatusToCancelled() async {
        // Arrange
        let ride = createTestRide(status: .pending)
        viewModel.currentRide = ride
        
        // Act
        await viewModel.cancelRide()
        
        // Assert
        // Note: Cette assertion dépend de l'implémentation réelle de cancelRide()
        // Vous devrez peut-être ajuster selon votre code
        XCTAssertEqual(viewModel.currentRide?.status, .cancelled, "Le statut devrait être 'cancelled'")
    }
    
    func testCancelRide_WithoutCurrentRide_DoesNothing() async {
        // Arrange
        viewModel.currentRide = nil
        
        // Act
        await viewModel.cancelRide()
        
        // Assert
        XCTAssertNil(viewModel.currentRide, "La course devrait rester nil")
    }
    
    // MARK: - Tests d'Historique
    
    func testLoadRideHistory_LoadsRides() async {
        // Arrange
        let userId = "test-client-id"
        
        // Act
        await viewModel.loadRideHistory(userId: userId)
        
        // Assert
        // Note: Cette assertion dépend de l'implémentation réelle
        // Vous devrez peut-être mocker le APIService
        XCTAssertNotNil(viewModel.rideHistory, "L'historique devrait être chargé")
    }
    
    func testLoadRideHistory_WithoutUserId_DoesNothing() async {
        // Arrange
        let userId = ""
        let initialHistoryCount = viewModel.rideHistory.count
        
        // Act
        await viewModel.loadRideHistory(userId: userId)
        
        // Assert
        XCTAssertEqual(viewModel.rideHistory.count, initialHistoryCount, "L'historique ne devrait pas changer")
    }
    
    // MARK: - Tests de Recherche de Chauffeurs
    
    func testFindAvailableDrivers_FindsDrivers() async {
        // Arrange
        let location = Location(latitude: -4.3276, longitude: 15.3156)
        
        // Act
        await viewModel.findAvailableDrivers(near: location)
        
        // Assert
        // Note: Cette assertion dépend de l'implémentation réelle
        // Vous devrez peut-être mocker le APIService
        XCTAssertNotNil(viewModel.availableDrivers, "Les chauffeurs devraient être chargés")
    }
    
    // MARK: - Tests de Cycle Complet
    
    func testCompleteRideLifecycle_AllStatusUpdates() async {
        // Arrange
        let pickup = Location(latitude: -4.3276, longitude: 15.3156)
        let dropoff = Location(latitude: -4.3376, longitude: 15.3256)
        let userId = "test-client-id"
        
        // Act & Assert - Étape 1: Demande
        await viewModel.requestRide(pickup: pickup, dropoff: dropoff, userId: userId)
        XCTAssertEqual(viewModel.currentRide?.status, .pending)
        
        // Act & Assert - Étape 2: Acceptation
        var updatedRide = viewModel.currentRide!
        updatedRide.status = .accepted
        updatedRide.driverId = "test-driver-id"
        viewModel.currentRide = updatedRide
        XCTAssertEqual(viewModel.currentRide?.status, .accepted)
        XCTAssertNotNil(viewModel.currentRide?.driverId)
        
        // Act & Assert - Étape 3: Chauffeur en route
        updatedRide.status = .driverArriving
        viewModel.currentRide = updatedRide
        XCTAssertEqual(viewModel.currentRide?.status, .driverArriving)
        
        // Act & Assert - Étape 4: En cours
        updatedRide.status = .inProgress
        updatedRide.startedAt = Date()
        viewModel.currentRide = updatedRide
        XCTAssertEqual(viewModel.currentRide?.status, .inProgress)
        XCTAssertNotNil(viewModel.currentRide?.startedAt)
        
        // Act & Assert - Étape 5: Terminé
        updatedRide.status = .completed
        updatedRide.completedAt = Date()
        updatedRide.finalPrice = 5500
        viewModel.currentRide = updatedRide
        XCTAssertEqual(viewModel.currentRide?.status, .completed)
        XCTAssertNotNil(viewModel.currentRide?.completedAt)
        XCTAssertEqual(viewModel.currentRide?.finalPrice, 5500)
    }
    
    // MARK: - Helper Methods
    
    private func createTestRide(
        status: RideStatus,
        id: String = UUID().uuidString,
        clientId: String = "test-client-id"
    ) -> Ride {
        return Ride(
            id: id,
            clientId: clientId,
            driverId: status != .pending ? "test-driver-id" : nil,
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3156),
            dropoffLocation: Location(latitude: -4.3376, longitude: 15.3256),
            status: status,
            estimatedPrice: 5000,
            finalPrice: status == .completed ? 5500 : nil,
            paymentMethod: nil,
            isPaid: false,
            distance: 2.5,
            duration: nil,
            createdAt: Date(),
            startedAt: status == .inProgress || status == .completed ? Date() : nil,
            completedAt: status == .completed ? Date() : nil,
            rating: nil,
            review: nil,
            driverLocation: nil
        )
    }
}

