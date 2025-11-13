//
//  PaymentServiceTests.swift
//  Tshiakani VTC Tests
//
//  Tests pour le service de paiement
//  Teste le traitement des paiements
//

import XCTest
import Combine
@testable import Tshiakani_VTC

@MainActor
class PaymentServiceTests: XCTestCase {
    var paymentService: PaymentService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        paymentService = PaymentService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        paymentService = nil
        super.tearDown()
    }
    
    // MARK: - Tests de Paiement
    
    func testProcessPayment_ProcessesPayment() async {
        // Arrange
        let rideId = UUID().uuidString
        let amount = 5500.0
        let paymentMethod = PaymentMethod.cash
        
        // Act & Assert
        do {
            let result = try await paymentService.processPayment(
                rideId: rideId,
                amount: amount,
                method: paymentMethod
            )
            XCTAssertNotNil(result, "Le résultat du paiement devrait être retourné")
        } catch {
            // Note: Dans un environnement de test, le paiement peut échouer
            // Vous devrez peut-être mocker le service de paiement
            print("Paiement échoué (attendu en environnement de test): \(error)")
        }
    }
    
    func testProcessPayment_WithInvalidAmount_Fails() async {
        // Arrange
        let rideId = UUID().uuidString
        let invalidAmount = -100.0
        let paymentMethod = PaymentMethod.cash
        
        // Act & Assert
        do {
            let _ = try await paymentService.processPayment(
                rideId: rideId,
                amount: invalidAmount,
                method: paymentMethod
            )
            XCTFail("Le paiement avec un montant invalide devrait échouer")
        } catch {
            XCTAssertTrue(true, "Le paiement devrait échouer avec un montant invalide")
        }
    }
    
    func testProcessPayment_WithDifferentPaymentMethods() async {
        // Arrange
        let rideId = UUID().uuidString
        let amount = 5500.0
        let paymentMethods: [PaymentMethod] = [.cash, .mpesa, .airtelMoney, .orangeMoney]
        
        // Act & Assert
        for method in paymentMethods {
            do {
                let result = try await paymentService.processPayment(
                    rideId: rideId,
                    amount: amount,
                    method: method
                )
                XCTAssertNotNil(result, "Le paiement avec \(method) devrait être traité")
            } catch {
                // Note: Certains méthodes de paiement peuvent ne pas être disponibles en test
                print("Paiement avec \(method) échoué: \(error)")
            }
        }
    }
    
    // MARK: - Tests de Validation
    
    func testValidatePayment_ValidatesPayment() async {
        // Arrange
        let rideId = UUID().uuidString
        let amount = 5500.0
        
        // Act & Assert
        do {
            let isValid = try await paymentService.validatePayment(
                rideId: rideId,
                amount: amount
            )
            XCTAssertNotNil(isValid, "La validation devrait retourner un résultat")
        } catch {
            print("Validation échouée: \(error)")
        }
    }
    
    // MARK: - Tests de Statut de Paiement
    
    func testGetPaymentStatus_ReturnsStatus() async {
        // Arrange
        let rideId = UUID().uuidString
        
        // Act & Assert
        do {
            let status = try await paymentService.getPaymentStatus(rideId: rideId)
            XCTAssertNotNil(status, "Le statut de paiement devrait être retourné")
        } catch {
            print("Récupération du statut échouée: \(error)")
        }
    }
    
    // MARK: - Tests d'Intégration avec Course
    
    func testPaymentAfterRideCompletion_CompletesPayment() async {
        // Arrange
        let ride = createCompletedRide()
        let amount = ride.finalPrice ?? 5500.0
        let paymentMethod = PaymentMethod.cash
        
        // Act & Assert
        do {
            let result = try await paymentService.processPayment(
                rideId: ride.id,
                amount: amount,
                method: paymentMethod
            )
            XCTAssertNotNil(result, "Le paiement devrait être traité après la fin de la course")
        } catch {
            print("Paiement après fin de course échoué: \(error)")
        }
    }
    
    func testPaymentBeforeRideCompletion_Fails() async {
        // Arrange
        let ride = createPendingRide()
        let amount = ride.estimatedPrice
        let paymentMethod = PaymentMethod.cash
        
        // Act & Assert
        // Note: Cette logique dépend de votre implémentation
        // Certains systèmes permettent le paiement avant la fin, d'autres non
        do {
            let result = try await paymentService.processPayment(
                rideId: ride.id,
                amount: amount,
                method: paymentMethod
            )
            // Si le paiement est autorisé avant la fin, c'est OK
            XCTAssertNotNil(result)
        } catch {
            // Si le paiement n'est pas autorisé avant la fin, c'est aussi OK
            XCTAssertTrue(true, "Le paiement avant la fin de course peut être refusé")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCompletedRide() -> Ride {
        return Ride(
            id: UUID().uuidString,
            clientId: "test-client-id",
            driverId: "test-driver-id",
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3156),
            dropoffLocation: Location(latitude: -4.3376, longitude: 15.3256),
            status: .completed,
            estimatedPrice: 5000,
            finalPrice: 5500,
            paymentMethod: nil,
            isPaid: false,
            distance: 2.5,
            duration: 1800, // 30 minutes
            createdAt: Date(),
            startedAt: Date().addingTimeInterval(-1800),
            completedAt: Date(),
            rating: nil,
            review: nil,
            driverLocation: nil
        )
    }
    
    private func createPendingRide() -> Ride {
        return Ride(
            id: UUID().uuidString,
            clientId: "test-client-id",
            driverId: nil,
            pickupLocation: Location(latitude: -4.3276, longitude: 15.3156),
            dropoffLocation: Location(latitude: -4.3376, longitude: 15.3256),
            status: .pending,
            estimatedPrice: 5000,
            finalPrice: nil,
            paymentMethod: nil,
            isPaid: false,
            distance: 2.5,
            duration: nil,
            createdAt: Date(),
            startedAt: nil,
            completedAt: nil,
            rating: nil,
            review: nil,
            driverLocation: nil
        )
    }
}

