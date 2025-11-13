//
//  ImageService.swift
//  Tshiakani VTC
//
//  Service pour gérer les images de profil
//

import UIKit
import Foundation

@MainActor
class ImageService {
    static let shared = ImageService()
    
    private let profileImageKey = "user_profile_image_base64"
    
    private init() {}
    
    /// Convertit une UIImage en base64
    func imageToBase64(_ image: UIImage) -> String? {
        // Redimensionner l'image pour éviter des fichiers trop volumineux
        let resizedImage = resizeImage(image, maxWidth: 500, maxHeight: 500)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    /// Convertit une chaîne base64 en UIImage
    func base64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    /// Sauvegarde l'image de profil localement
    func saveProfileImage(_ image: UIImage) {
        if let base64String = imageToBase64(image) {
            UserDefaults.standard.set(base64String, forKey: profileImageKey)
        }
    }
    
    /// Charge l'image de profil depuis le stockage local
    func loadProfileImage() -> UIImage? {
        guard let base64String = UserDefaults.standard.string(forKey: profileImageKey) else {
            return nil
        }
        
        return base64ToImage(base64String)
    }
    
    /// Supprime l'image de profil du stockage local
    func deleteProfileImage() {
        UserDefaults.standard.removeObject(forKey: profileImageKey)
    }
    
    /// Redimensionne une image pour qu'elle ne dépasse pas les dimensions maximales
    private func resizeImage(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        
        // Si l'image est plus petite que les dimensions maximales, la retourner telle quelle
        if size.width <= maxWidth && size.height <= maxHeight {
            return image
        }
        
        // Calculer le ratio de redimensionnement
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio)
        
        // Nouvelles dimensions
        let newWidth = size.width * ratio
        let newHeight = size.height * ratio
        
        // Redimensionner l'image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}

