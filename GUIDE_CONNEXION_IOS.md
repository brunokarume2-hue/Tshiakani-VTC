# 📱 Guide de Connexion iOS - Tshiakani VTC

Guide complet pour connecter l'application iOS au backend.

## 🎯 Configuration

### 1. Configuration Automatique (Recommandé)

L'application iOS est **déjà configurée** pour se connecter au backend local en mode DEBUG.

**Fichier:** `Tshiakani VTC/Services/ConfigurationService.swift`

```swift
var apiBaseURL: String {
    #if DEBUG
    return "http://localhost:3000/api"  // ✅ Déjà configuré
    #else
    return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
    #endif
}
```

### 2. Problème: iPhone Simulator et localhost

**Problème:** L'iPhone Simulator ne peut pas accéder à `localhost` directement.

**Solution 1: Utiliser l'adresse IP de votre machine**

#### Trouver votre adresse IP

```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
```

**Ou plus simple:**
```bash
ipconfig getifaddr en0
```

#### Configurer dans l'app iOS

**Option A: Modifier ConfigurationService.swift**

```swift
var apiBaseURL: String {
    #if DEBUG
    // Pour iPhone Simulator, utilisez l'IP de votre machine
    // Remplacez 192.168.1.X par votre adresse IP
    #if targetEnvironment(simulator)
    return "http://192.168.1.X:3000/api"  // ← Votre IP ici
    #else
    return "http://localhost:3000/api"
    #endif
    #else
    return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
    #endif
}
```

**Option B: Utiliser UserDefaults (Recommandé)**

L'app iOS supporte déjà la configuration via UserDefaults ! 

1. **Dans l'app iOS**, allez dans les paramètres
2. Trouvez la section "Configuration Backend"
3. Entrez votre adresse IP:
   - **API Base URL:** `http://192.168.1.X:3000/api`
   - **Socket Base URL:** `http://192.168.1.X:3000`

**Vue disponible:** `BackendConfigurationView` dans l'app

### 3. Configurer CORS dans le Backend

**Fichier:** `backend/server.postgres.js`

Assurez-vous que CORS autorise les requêtes depuis l'app iOS:

```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN || [
    "http://localhost:3001",
    "http://localhost:5173",
    "capacitor://localhost",     // Pour Capacitor
    "ionic://localhost",         // Pour Ionic
    "http://192.168.1.X:3000"    // Votre IP locale
  ],
  credentials: true
}));
```

**Mettre à jour .env:**
```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.X:3000
```

### 4. Tester la Connexion

#### Test depuis l'app iOS

1. **Ouvrir l'app iOS** dans Xcode
2. **Lancer l'app** sur le simulateur ou un appareil
3. **Aller dans les paramètres** de l'app
4. **Tester la connexion** via "BackendConnectionTestView"

#### Test manuel

**Dans l'app iOS, créez une fonction de test:**

```swift
func testConnection() async {
    let config = ConfigurationService.shared
    let url = URL(string: "\(config.apiBaseURL)/../health")!
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(HealthResponse.self, from: data)
        print("✅ Connexion réussie: \(response.status)")
    } catch {
        print("❌ Erreur: \(error)")
    }
}
```

## 🔧 Configuration Détaillée

### URLs Configurées

| Environnement | API URL | Socket URL |
|--------------|---------|------------|
| **DEBUG (Simulator)** | `http://localhost:3000/api` | `http://localhost:3000` |
| **DEBUG (Appareil)** | `http://192.168.1.X:3000/api` | `http://192.168.1.X:3000` |
| **RELEASE** | Cloud Run URL | Cloud Run URL |

### Configuration via UserDefaults

L'app iOS permet de configurer les URLs via UserDefaults:

```swift
// Dans l'app
UserDefaults.standard.set("http://192.168.1.X:3000/api", forKey: "api_base_url")
UserDefaults.standard.set("http://192.168.1.X:3000", forKey: "socket_base_url")
```

### Configuration via Info.plist

**Fichier:** `Tshiakani VTC/Info.plist`

```xml
<key>API_BASE_URL</key>
<string>http://192.168.1.X:3000/api</string>
<key>WS_BASE_URL</key>
<string>http://192.168.1.X:3000</string>
```

## 🧪 Tests

### 1. Test Health Check

```swift
let config = ConfigurationService.shared
let url = URL(string: "\(config.apiBaseURL)/../health")!
// Tester la connexion
```

### 2. Test Authentification

```swift
let apiService = APIService.shared
try await apiService.post(endpoint: "/auth/signin", body: [
    "phoneNumber": "+243900000000",
    "name": "Test User"
])
```

### 3. Test WebSocket

```swift
let socketService = SocketIOService.shared
socketService.connect()
// Vérifier la connexion
```

## ✅ Checklist

- [ ] Adresse IP de la machine trouvée
- [ ] ConfigurationService.swift configuré (ou UserDefaults)
- [ ] CORS configuré dans le backend
- [ ] Backend démarré sur le port 3000
- [ ] Test de connexion réussi
- [ ] Authentification fonctionnelle
- [ ] WebSocket fonctionnel
- [ ] Création de course testée

## 🐛 Dépannage

### Erreur: "Could not connect to server"

**Solutions:**
1. Vérifier que le backend est démarré
2. Vérifier l'adresse IP dans ConfigurationService
3. Vérifier que CORS autorise votre IP
4. Vérifier le firewall macOS

### Erreur: "CORS policy"

**Solution:**
```bash
# Mettre à jour CORS dans .env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.X:3000
```

### Erreur: "Network request failed"

**Solutions:**
1. Vérifier que le backend écoute sur toutes les interfaces (`0.0.0.0`)
2. Vérifier que le port 3000 n'est pas bloqué par le firewall
3. Utiliser l'adresse IP au lieu de localhost

## 📚 Documentation

- **ConfigurationService:** `Tshiakani VTC/Services/ConfigurationService.swift`
- **APIService:** `Tshiakani VTC/Services/APIService.swift`
- **SocketIOService:** `Tshiakani VTC/Services/SocketIOService.swift`

---

**Date:** Novembre 2025  
**Version:** 1.0.0

