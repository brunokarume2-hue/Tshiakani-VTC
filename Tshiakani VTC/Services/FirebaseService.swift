//
//  FirebaseService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation
// TODO: Installer Firebase via Swift Package Manager
// File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Service principal pour l'intégration Firebase
/// Gère l'authentification, Firestore et les listeners en temps réel
class FirebaseService {
    static let shared = FirebaseService()
    
    private let db: Firestore
    
    private init() {
        // Firestore est initialisé automatiquement après FirebaseApp.configure()
        db = Firestore.firestore()
        
        // Configuration des paramètres Firestore
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true // Cache local
        db.settings = settings
    }
    
    // MARK: - Authentification
    
    /// Envoie un code OTP au numéro de téléphone
    func signIn(phoneNumber: String) async throws {
        #if canImport(FirebaseAuth)
        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        
        // Stocker le verificationID pour la vérification
        UserDefaults.standard.set(verificationID, forKey: "firebase_verification_id")
        UserDefaults.standard.set(phoneNumber, forKey: "firebase_phone_number")
        #else
        throw FirebaseError.notConfigured
        #endif
    }
    
    /// Vérifie le code OTP et connecte l'utilisateur
    func verifyOTP(phoneNumber: String, code: String) async throws -> User {
        #if canImport(FirebaseAuth)
        guard let verificationID = UserDefaults.standard.string(forKey: "firebase_verification_id") else {
            throw FirebaseError.verificationIDNotFound
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        // Convertir FirebaseUser en User de l'app
        return User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? "",
            phoneNumber: phoneNumber,
            email: firebaseUser.email,
            role: .client,
            isVerified: firebaseUser.isEmailVerified
        )
        #else
        throw FirebaseError.notConfigured
        #endif
    }
    
    /// Déconnecte l'utilisateur actuel
    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "firebase_verification_id")
        UserDefaults.standard.removeObject(forKey: "firebase_phone_number")
        #endif
    }
    
    /// Récupère l'utilisateur actuellement connecté
    func getCurrentUser() -> User? {
        #if canImport(FirebaseAuth)
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        // Convertir FirebaseUser en User de l'app
        return User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? "",
            phoneNumber: firebaseUser.phoneNumber ?? "",
            email: firebaseUser.email,
            role: .client,
            isVerified: firebaseUser.isEmailVerified
        )
        #else
        return nil
        #endif
    }
    
    // MARK: - Firestore Operations
    
    /// Insère un document dans une collection
    func insert<T: Codable>(_ value: T, into collection: String) async throws {
        let docRef = db.collection(collection).document()
        
        do {
            try docRef.setData(from: value)
        } catch {
            throw FirebaseError.databaseError(error.localizedDescription)
        }
    }
    
    /// Insère un document avec un ID spécifique
    func insert<T: Codable>(_ value: T, withId id: String, into collection: String) async throws {
        let docRef = db.collection(collection).document(id)
        
        do {
            try docRef.setData(from: value)
        } catch {
            throw FirebaseError.databaseError(error.localizedDescription)
        }
    }
    
    /// Met à jour un document
    func update<T: Codable>(_ value: T, documentId: String, in collection: String) async throws {
        let docRef = db.collection(collection).document(documentId)
        
        do {
            try docRef.setData(from: value, merge: true)
        } catch {
            throw FirebaseError.databaseError(error.localizedDescription)
        }
    }
    
    /// Récupère un document par ID
    func get<T: Codable>(_ type: T.Type, documentId: String, from collection: String) async throws -> T? {
        let docRef = db.collection(collection).document(documentId)
        
        let document = try await docRef.getDocument()
        
        guard document.exists else {
            return nil
        }
        
        return try document.data(as: type)
    }
    
    /// Récupère tous les documents d'une collection avec filtres optionnels
    func select<T: Codable>(
        from collection: String,
        whereField field: String? = nil,
        isEqualTo value: Any? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        var query: Query = db.collection(collection)
        
        if let field = field, let value = value {
            query = query.whereField(field, isEqualTo: value)
        }
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }
    
    /// Supprime un document
    func delete(documentId: String, from collection: String) async throws {
        try await db.collection(collection).document(documentId).delete()
    }
    
    // MARK: - Realtime Listeners
    
    /// S'abonne aux changements d'une collection
    func listen<T: Codable>(
        to collection: String,
        whereField field: String? = nil,
        isEqualTo value: Any? = nil,
        onDocumentChange: @escaping (ChangeType, T) -> Void
    ) -> ListenerRegistration {
        var query: Query = db.collection(collection)
        
        if let field = field, let value = value {
            query = query.whereField(field, isEqualTo: value)
        }
        
        return query.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else {
                if let error = error {
                    print("Erreur listener: \(error.localizedDescription)")
                }
                return
            }
            
            snapshot.documentChanges.forEach { change in
                do {
                    let data = try change.document.data(as: T.self)
                    onDocumentChange(change.type.changeType, data)
                } catch {
                    print("Erreur décodage: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// S'abonne aux changements d'un document spécifique
    func listen<T: Codable>(
        toDocument documentId: String,
        in collection: String,
        onDocumentChange: @escaping (T?) -> Void
    ) -> ListenerRegistration {
        let docRef = db.collection(collection).document(documentId)
        
        return docRef.addSnapshotListener { document, error in
            guard let document = document else {
                if let error = error {
                    print("Erreur listener: \(error.localizedDescription)")
                }
                onDocumentChange(nil)
                return
            }
            
            do {
                let data = try document.data(as: T.self)
                onDocumentChange(data)
            } catch {
                print("Erreur décodage: \(error.localizedDescription)")
                onDocumentChange(nil)
            }
        }
    }
}

// MARK: - Errors

enum FirebaseError: LocalizedError {
    case notConfigured
    case verificationIDNotFound
    case authenticationFailed
    case databaseError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase n'est pas configuré correctement"
        case .verificationIDNotFound:
            return "ID de vérification introuvable. Veuillez réessayer."
        case .authenticationFailed:
            return "Échec de l'authentification"
        case .databaseError(let message):
            return "Erreur base de données: \(message)"
        case .networkError:
            return "Erreur réseau"
        }
    }
}

// MARK: - DocumentChangeType Helper

extension DocumentChangeType {
    var changeType: ChangeType {
        switch self {
        case .added:
            return .added
        case .modified:
            return .modified
        case .removed:
            return .removed
        }
    }
}

enum ChangeType {
    case added
    case modified
    case removed
}

#else
// Fallback quand Firebase n'est pas installé
class FirebaseService {
    static let shared = FirebaseService()
    private init() {}
    
    func signIn(phoneNumber: String) async throws {
        throw FirebaseError.notConfigured
    }
    
    func verifyOTP(phoneNumber: String, code: String) async throws -> User {
        throw FirebaseError.notConfigured
    }
    
    func getCurrentUser() -> User? {
        return nil
    }
    
    func signOut() throws {
        throw FirebaseError.notConfigured
    }
    
    func getCurrentUser() -> Any? {
        return nil
    }
    
    func insert<T: Codable>(_ value: T, into collection: String) async throws {
        throw FirebaseError.notConfigured
    }
    
    func insert<T: Codable>(_ value: T, withId id: String, into collection: String) async throws {
        throw FirebaseError.notConfigured
    }
    
    func update<T: Codable>(_ value: T, documentId: String, in collection: String) async throws {
        throw FirebaseError.notConfigured
    }
    
    func get<T: Codable>(_ type: T.Type, documentId: String, from collection: String) async throws -> T? {
        throw FirebaseError.notConfigured
    }
    
    func select<T: Codable>(from collection: String, whereField field: String?, isEqualTo value: Any?, limit: Int?) async throws -> [T] {
        throw FirebaseError.notConfigured
    }
}

enum ChangeType {
    case added
    case modified
    case removed
}

enum FirebaseError: LocalizedError {
    case notConfigured
    var errorDescription: String? {
        return "Firebase n'est pas configuré"
    }
}
#endif

