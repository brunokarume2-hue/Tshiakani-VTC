# Configuration iOS pour Production

## Mise à Jour de l'URL de l'API

### Option 1 : ConfigurationService.swift

Dans `Tshiakani VTC/Services/ConfigurationService.swift`, mettre à jour la propriété `apiBaseURL` :

```swift
var apiBaseURL: String {
  // Vérifier d'abord UserDefaults (priorité absolue)
  if let customURL = UserDefaults.standard.string(forKey: "api_base_url"), !customURL.isEmpty {
    return customURL
  }
  
  // Vérifier Info.plist en priorité (pour Debug et Release)
  if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
    return url
  }
  
  #if DEBUG
  // Sur le simulateur, localhost fonctionne directement
  #if targetEnvironment(simulator)
  return "http://localhost:3000"
  #else
  // Sur un appareil réel, utiliser l'IP locale ou l'URL de production
  if let deviceURL = UserDefaults.standard.string(forKey: "api_base_url_device"), !deviceURL.isEmpty {
    return deviceURL
  }
  // Fallback vers Cloud Run même en DEBUG si aucune configuration locale
  return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
  #endif
  #else
  // Pour la production, utiliser l'URL Cloud Run
  return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
  #endif
}
```

### Option 2 : Info.plist

Ajouter la clé `API_BASE_URL` dans `Info.plist` :

```xml
<key>API_BASE_URL</key>
<string>https://your-cloud-run-url.run.app</string>
```

### Option 3 : UserDefaults (pour tests)

Dans l'application, vous pouvez définir une URL personnalisée :

```swift
UserDefaults.standard.set("https://your-custom-url.com", forKey: "api_base_url")
```

## Mise à Jour de l'URL WebSocket

Dans `ConfigurationService.swift`, mettre à jour la propriété `socketBaseURL` :

```swift
var socketBaseURL: String {
  // Vérifier d'abord UserDefaults (priorité absolue)
  if let customURL = UserDefaults.standard.string(forKey: "socket_base_url"), !customURL.isEmpty {
    return customURL
  }
  
  // Vérifier Info.plist en priorité (pour Debug et Release)
  if let url = Bundle.main.object(forInfoDictionaryKey: "WS_BASE_URL") as? String, !url.isEmpty {
    return url
  }
  
  #if DEBUG
  // Sur le simulateur, localhost fonctionne directement
  #if targetEnvironment(simulator)
  return "http://localhost:3000"
  #else
  // Sur un appareil réel, utiliser l'IP locale ou l'URL de production
  if let deviceURL = UserDefaults.standard.string(forKey: "socket_base_url_device"), !deviceURL.isEmpty {
    return deviceURL
  }
  // Fallback vers Cloud Run même en DEBUG si aucune configuration locale
  return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
  #endif
  #else
  // Pour la production, utiliser l'URL Cloud Run
  return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
  #endif
}
```

## Variables d'Environnement Xcode

### Pour Debug

1. Ouvrir Xcode
2. Sélectionner le schéma de build
3. Edit Scheme → Run → Arguments
4. Ajouter les variables d'environnement :
   - `API_BASE_URL` = `http://localhost:3000`
   - `WS_BASE_URL` = `http://localhost:3000`

### Pour Release

1. Ouvrir Xcode
2. Sélectionner le schéma de build Release
3. Edit Scheme → Run → Arguments
4. Ajouter les variables d'environnement :
   - `API_BASE_URL` = `https://your-cloud-run-url.run.app`
   - `WS_BASE_URL` = `https://your-cloud-run-url.run.app`

## Configuration pour App Store

### 1. Info.plist

Ajouter les clés dans `Info.plist` :

```xml
<key>API_BASE_URL</key>
<string>https://your-cloud-run-url.run.app</string>
<key>WS_BASE_URL</key>
<string>https://your-cloud-run-url.run.app</string>
```

### 2. Build Settings

Dans les Build Settings d'Xcode, ajouter les variables d'environnement pour les différentes configurations (Debug, Release, etc.).

## Tests avec l'Application iOS

### 1. Tests Locaux

1. Démarrer le backend localement :
   ```bash
   cd backend
   npm run dev
   ```

2. Configurer l'application iOS pour utiliser l'URL locale :
   - Définir `API_BASE_URL` dans UserDefaults ou Info.plist
   - Utiliser `http://localhost:3000` pour le simulateur
   - Utiliser `http://<votre-ip-local>:3000` pour un appareil réel

### 2. Tests avec Production

1. Configurer l'application iOS pour utiliser l'URL de production :
   - Définir `API_BASE_URL` dans Info.plist
   - Utiliser l'URL Cloud Run : `https://your-cloud-run-url.run.app`

2. Tester toutes les fonctionnalités :
   - Authentification
   - Support
   - Favorites
   - Chat
   - Scheduled Rides
   - Share
   - SOS

## Vérification de la Configuration

### 1. Vérifier l'URL de l'API

Dans l'application iOS, ajouter un log pour vérifier l'URL utilisée :

```swift
print("🌐 API Base URL: \(ConfigurationService.shared.apiBaseURL)")
print("🌐 Socket Base URL: \(ConfigurationService.shared.socketBaseURL)")
```

### 2. Tester la Connexion

```swift
// Tester la connexion au backend
Task {
    do {
        let response = try await APIService.shared.get(endpoint: "/health", queryItems: nil) as HealthResponse
        print("✅ Backend connecté: \(response)")
    } catch {
        print("❌ Erreur de connexion: \(error)")
    }
}
```

## Problèmes Courants

### Erreur de Connexion

- **Cause** : URL incorrecte ou backend non accessible
- **Solution** : Vérifier l'URL dans `ConfigurationService` et s'assurer que le backend est accessible

### Erreur CORS

- **Cause** : CORS non configuré correctement sur le backend
- **Solution** : Vérifier la configuration CORS dans `server.postgres.js`

### Erreur SSL/TLS

- **Cause** : Certificat SSL invalide ou expiré
- **Solution** : Vérifier que le certificat SSL de Cloud Run est valide

### Erreur de Timeout

- **Cause** : Timeout trop court ou backend trop lent
- **Solution** : Augmenter le timeout dans `ConfigurationService` ou optimiser le backend

## Notes

- L'URL de l'API peut être modifiée dynamiquement via UserDefaults
- L'URL WebSocket doit correspondre à l'URL de l'API
- Les variables d'environnement Xcode ont priorité sur Info.plist
- UserDefaults a priorité absolue sur toutes les autres configurations

