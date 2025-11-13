//
//  APIErrorView.swift
//  Tshiakani VTC
//
//  Composant réutilisable pour afficher les erreurs API de manière élégante
//

import SwiftUI

/// Type d'erreur API
enum APIErrorType {
    case network
    case server
    case authentication
    case validation
    case notFound
    case timeout
    case unknown
    
    var icon: String {
        switch self {
        case .network:
            return "wifi.slash"
        case .server:
            return "exclamationmark.triangle.fill"
        case .authentication:
            return "lock.fill"
        case .validation:
            return "exclamationmark.circle.fill"
        case .notFound:
            return "magnifyingglass"
        case .timeout:
            return "clock.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .network:
            return "Erreur de connexion"
        case .server:
            return "Erreur serveur"
        case .authentication:
            return "Authentification requise"
        case .validation:
            return "Données invalides"
        case .notFound:
            return "Non trouvé"
        case .timeout:
            return "Délai d'attente dépassé"
        case .unknown:
            return "Erreur inconnue"
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .network:
            return "Vérifiez votre connexion Internet et réessayez."
        case .server:
            return "Le serveur rencontre un problème. Veuillez réessayer plus tard."
        case .authentication:
            return "Votre session a expiré. Veuillez vous reconnecter."
        case .validation:
            return "Les informations saisies sont incorrectes."
        case .notFound:
            return "La ressource demandée est introuvable."
        case .timeout:
            return "La requête prend trop de temps. Veuillez réessayer."
        case .unknown:
            return "Une erreur s'est produite. Veuillez réessayer."
        }
    }
}

/// Vue d'erreur API réutilisable
struct APIErrorView: View {
    let error: APIError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(error: APIError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: AppDesign.spacingL) {
            // Icône d'erreur
            ZStack {
                Circle()
                    .fill(errorType.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: errorType.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(errorType.color)
            }
            .padding(.top, AppDesign.spacingM)
            
            // Titre
            Text(errorType.title)
                .font(AppTypography.title2(weight: .bold))
                .foregroundColor(AppColors.primaryText)
            
            // Message
            Text(error.message ?? errorType.defaultMessage)
                .font(AppTypography.body())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.spacingM)
            
            // Boutons d'action
            VStack(spacing: AppDesign.spacingM) {
                if let onRetry = onRetry {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        onRetry()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Réessayer")
                        }
                        .font(AppTypography.headline(weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(AppColors.accentOrange)
                    .cornerRadius(AppDesign.cornerRadiusL)
                    .buttonShadow()
                }
                
                if let onDismiss = onDismiss {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Fermer")
                            .font(AppTypography.subheadline(weight: .semibold))
                            .foregroundColor(AppColors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, AppDesign.spacingM)
            .padding(.bottom, AppDesign.spacingM)
        }
        .padding(AppDesign.spacingL)
        .background(AppColors.background)
        .cornerRadius(AppDesign.cornerRadiusXL)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    private var errorType: APIErrorType {
        error.type
    }
}

extension APIErrorType {
    var color: Color {
        switch self {
        case .network:
            return AppColors.warning
        case .server:
            return AppColors.error
        case .authentication:
            return AppColors.error
        case .validation:
            return AppColors.warning
        case .notFound:
            return AppColors.secondaryText
        case .timeout:
            return AppColors.warning
        case .unknown:
            return AppColors.secondaryText
        }
    }
}

/// Modèle d'erreur API
struct APIError: Error, LocalizedError {
    let type: APIErrorType
    let message: String?
    let statusCode: Int?
    let underlyingError: Error?
    
    init(type: APIErrorType, message: String? = nil, statusCode: Int? = nil, underlyingError: Error? = nil) {
        self.type = type
        self.message = message
        self.statusCode = statusCode
        self.underlyingError = underlyingError
    }
    
    var errorDescription: String? {
        return message ?? type.defaultMessage
    }
    
    /// Crée une APIError à partir d'une NSError
    static func from(_ error: Error) -> APIError {
        if let nsError = error as NSError? {
            // Vérifier le code d'erreur
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    return APIError(type: .network, message: "Aucune connexion Internet disponible.", underlyingError: error)
                case NSURLErrorTimedOut:
                    return APIError(type: .timeout, message: "La requête a pris trop de temps.", underlyingError: error)
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    return APIError(type: .network, message: "Impossible de se connecter au serveur.", underlyingError: error)
                default:
                    return APIError(type: .network, message: error.localizedDescription, underlyingError: error)
                }
            }
            
            // Vérifier le code de statut HTTP
            if let statusCode = nsError.userInfo["statusCode"] as? Int {
                switch statusCode {
                case 401, 403:
                    return APIError(type: .authentication, message: "Authentification requise.", statusCode: statusCode, underlyingError: error)
                case 404:
                    return APIError(type: .notFound, message: "Ressource non trouvée.", statusCode: statusCode, underlyingError: error)
                case 400, 422:
                    return APIError(type: .validation, message: nsError.localizedDescription, statusCode: statusCode, underlyingError: error)
                case 500...599:
                    return APIError(type: .server, message: "Erreur serveur. Veuillez réessayer plus tard.", statusCode: statusCode, underlyingError: error)
                default:
                    return APIError(type: .unknown, message: error.localizedDescription, statusCode: statusCode, underlyingError: error)
                }
            }
        }
        
        return APIError(type: .unknown, message: error.localizedDescription, underlyingError: error)
    }
}

/// Modifier pour afficher une erreur API en overlay
struct APIErrorOverlay: ViewModifier {
    @Binding var error: APIError?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let error = error {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        self.error = nil
                    }
                
                APIErrorView(error: error, onRetry: onRetry) {
                    self.error = nil
                }
                .padding(AppDesign.spacingXL)
            }
        }
    }
}

extension View {
    /// Affiche une erreur API en overlay
    func apiErrorOverlay(error: Binding<APIError?>, onRetry: (() -> Void)? = nil) -> some View {
        self.modifier(APIErrorOverlay(error: error, onRetry: onRetry))
    }
}

#Preview {
    VStack(spacing: 20) {
        APIErrorView(
            error: APIError(type: .network, message: "Vérifiez votre connexion Internet."),
            onRetry: {
                print("Retry")
            }
        )
        
        APIErrorView(
            error: APIError(type: .server, message: "Le serveur rencontre un problème."),
            onRetry: {
                print("Retry")
            },
            onDismiss: {
                print("Dismiss")
            }
        )
    }
    .padding()
    .background(AppColors.secondaryBackground)
}

