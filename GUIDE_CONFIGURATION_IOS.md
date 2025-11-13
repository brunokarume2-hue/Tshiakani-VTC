# 📱 Guide de Configuration iOS - Tshiakani VTC

## ✅ Configuration via l'Interface de l'App

L'application iOS dispose déjà d'une interface de configuration intégrée ! Voici comment l'utiliser :

### 📍 Accès à la Configuration

1. **Ouvrir l'app iOS** dans Xcode
2. **Lancer l'app** sur le simulateur ou un appareil réel
3. **Aller dans les Paramètres** de l'app :
   - Ouvrir le menu de navigation (☰)
   - Sélectionner "Paramètres"
4. **Section "Développement"** (visible uniquement en mode DEBUG) :
   - Sélectionner "Test de connexion backend"
   - Puis "Configurer l'URL du backend"

### ⚙️ Configuration des URLs

Dans l'écran "Configuration Backend" :

1. **API Base URL:**
   - Entrer : `http://192.168.1.79:3000/api`
   - Ou laisser vide pour utiliser la valeur par défaut

2. **Socket Base URL:**
   - Entrer : `http://192.168.1.79:3000`
   - Ou laisser vide pour utiliser la valeur par défaut

3. **Valider:**
   - Appuyer sur "Terminé" pour enregistrer

### 🔄 Réinitialisation

Pour revenir aux valeurs par défaut :
- Appuyer sur "Réinitialiser aux valeurs par défaut"
- Les champs seront vidés
- L'app utilisera les valeurs par défaut du code

---

## 🎯 Configuration Automatique

L'app est déjà configurée avec votre IP par défaut :

### Simulateur iOS
- **API:** `http://localhost:3000/api` ✅
- **Socket:** `http://localhost:3000` ✅

### Appareil Réel
- **API:** `http://192.168.1.79:3000/api` ✅ (déjà configuré)
- **Socket:** `http://192.168.1.79:3000` ✅ (déjà configuré)

**Vous n'avez donc pas besoin de configurer manuellement si vous utilisez un appareil réel !**

---

## 🧪 Test de la Connexion

Après configuration, vous pouvez tester la connexion :

1. **Dans les Paramètres:**
   - Aller dans "Test de connexion backend"
   - Appuyer sur "Tester la connexion"

2. **Vérifier les résultats:**
   - ✅ Connexion réussie → Backend accessible
   - ❌ Connexion échouée → Vérifier l'URL et que le serveur est démarré

---

## 🔧 Configuration Manuelle (Alternative)

Si vous préférez configurer manuellement dans le code :

### Option 1: Modifier ConfigurationService.swift

**Fichier:** `Tshiakani VTC/Services/ConfigurationService.swift`

**Pour un appareil réel:**
```swift
// Ligne 38 - API Base URL
return "http://192.168.1.79:3000/api"

// Ligne 68 - Socket Base URL
return "http://192.168.1.79:3000"
```

### Option 2: Utiliser UserDefaults (Programmatique)

```swift
UserDefaults.standard.set("http://192.168.1.79:3000/api", forKey: "api_base_url")
UserDefaults.standard.set("http://192.168.1.79:3000", forKey: "socket_base_url")
```

---

## 📋 Checklist de Configuration

### Configuration via Interface (Recommandé)
- [ ] Ouvrir l'app iOS
- [ ] Aller dans Paramètres
- [ ] Ouvrir "Test de connexion backend"
- [ ] Ouvrir "Configurer l'URL du backend"
- [ ] Entrer les URLs :
  - [ ] API Base URL: `http://192.168.1.79:3000/api`
  - [ ] Socket Base URL: `http://192.168.1.79:3000`
- [ ] Appuyer sur "Terminé"
- [ ] Tester la connexion

### Configuration Automatique (Appareil Réel)
- [x] L'app utilise déjà l'IP `192.168.1.79` par défaut
- [ ] Vérifier que le serveur backend est démarré
- [ ] Tester la connexion depuis l'app

---

## ✅ Vérification

### 1. Vérifier que le Backend est Démarré

```bash
curl http://localhost:3000/health
```

**Résultat attendu:**
```json
{"status":"OK","database":"connected","timestamp":"..."}
```

### 2. Vérifier CORS

Le backend doit autoriser votre IP. Vérifier dans `backend/.env` :

```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.79:3000
```

### 3. Tester depuis l'App iOS

1. Ouvrir l'app
2. Aller dans Paramètres
3. Ouvrir "Test de connexion backend"
4. Appuyer sur "Tester la connexion"
5. Vérifier que la connexion réussit

---

## 🎉 Résultat

Une fois configuré :

- ✅ L'app se connecte au backend
- ✅ L'authentification fonctionne
- ✅ Les courses peuvent être créées
- ✅ WebSocket fonctionne pour les mises à jour temps réel

---

## 🐛 Dépannage

### Erreur: "Cannot connect to server"

**Solutions:**
1. Vérifier que le backend est démarré : `curl http://localhost:3000/health`
2. Vérifier l'URL dans la configuration (doit correspondre à l'IP du serveur)
3. Vérifier que l'appareil iOS est sur le même réseau WiFi
4. Vérifier CORS dans `backend/.env`

### Erreur: "CORS policy"

**Solution:**
```bash
# Vérifier CORS dans backend/.env
cat backend/.env | grep CORS_ORIGIN

# Si l'IP n'est pas présente, l'ajouter
./scripts/configurer-tout.sh
```

### L'interface de configuration n'apparaît pas

**Solution:**
- L'interface n'est visible qu'en mode DEBUG
- Compiler l'app en mode DEBUG
- Ou modifier `SettingsView.swift` pour la rendre visible en production

---

## 📚 Documentation

- **ConfigurationService.swift** - Service de configuration
- **BackendConnectionTestView.swift** - Interface de test et configuration
- **SettingsView.swift** - Écran de paramètres
- **GUIDE_CONNEXION_IOS.md** - Guide de connexion complet

---

**Date:** Novembre 2025  
**Version:** 1.0.0  
**IP Locale:** 192.168.1.79

