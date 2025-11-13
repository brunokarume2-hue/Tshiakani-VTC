//
//  GoogleAuthService.swift
//  Tshiakani VTC
//
//  Service pour l'authentification Google Sign-In
//

import Foundation
import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class GoogleAuthService {
    static let shared = GoogleAuthService()
    
    private init() {}
    
    /// Configure Google Sign-In avec le client ID
    func configure(clientID: String) {
        #if canImport(GoogleSignIn)
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("⚠️ GoogleService-Info.plist non trouvé, utilisation du clientID fourni")
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            return
        }
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign-In configuré avec clientID: \(clientId.prefix(20))...")
        #else
        print("⚠️ GoogleSignIn SDK non disponible")
        #endif
    }
    
    /// Lance le processus de connexion Google
    /// - Parameter presentingViewController: Le ViewController qui présente la vue de connexion
    /// - Returns: Les informations de l'utilisateur Google (id, email, name, idToken)
    func signIn(presentingViewController: UIViewController) async throws -> GoogleUserInfo {
        #if canImport(GoogleSignIn)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.noIdToken
        }
        
        let profile = result.user.profile
        
        return GoogleUserInfo(
            id: result.user.userID ?? "",
            email: profile?.email ?? "",
            name: profile?.name ?? "",
            givenName: profile?.givenName ?? "",
            familyName: profile?.familyName ?? "",
            photoURL: profile?.imageURL(withDimension: 200)?.absoluteString,
            idToken: idToken
        )
        #else
        throw GoogleAuthError.notConfigured
        #endif
    }
    
    /// Déconnecte l'utilisateur Google
    func signOut() {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }
    
    /// Vérifie si un utilisateur est connecté
    func isSignedIn() -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.currentUser != nil
        #else
        return false
        #endif
    }
    
    /// Récupère l'utilisateur actuellement connecté
    func getCurrentUser() -> GoogleUserInfo? {
        #if canImport(GoogleSignIn)
        guard let user = GIDSignIn.sharedInstance.currentUser,
              let idToken = user.idToken?.tokenString else {
            return nil
        }
        
        let profile = user.profile
        
        return GoogleUserInfo(
            id: user.userID ?? "",
            email: profile?.email ?? "",
            name: profile?.name ?? "",
            givenName: profile?.givenName ?? "",
            familyName: profile?.familyName ?? "",
            photoURL: profile?.imageURL(withDimension: 200)?.absoluteString,
            idToken: idToken
        )
        #else
        return nil
        #endif
    }
}

// MARK: - Models

struct GoogleUserInfo {
    let id: String
    let email: String
    let name: String
    let givenName: String
    let familyName: String
    let photoURL: String?
    let idToken: String
}

// MARK: - Errors

enum GoogleAuthError: LocalizedError {
    case notConfigured
    case presentationError
    case noIdToken
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In n'est pas configuré. Veuillez installer le SDK GoogleSignIn."
        case .presentationError:
            return "Erreur lors de la présentation de la vue de connexion."
        case .noIdToken:
            return "Impossible d'obtenir le token d'identification Google."
        case .cancelled:
            return "Connexion Google annulée."
        }
    }
}

