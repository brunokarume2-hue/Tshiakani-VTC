# 🔧 Correction des Intégrations - Guide Complet

## 📋 Problèmes Identifiés

### ❌ Problème 1 : URL Backend Incohérente

**Apps iOS (client et driver)** pointent vers :
- ❌ `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app` (ancienne URL)

**Backend actuel déployé** :
- ✅ `https://tshiakani-vtc-backend-418102154417.us-central1.run.app` (URL correcte)

**Impact** : Les apps iOS ne peuvent pas se connecter au backend déployé.

---

### ❌ Problème 2 : Dashboard Frontend Non Configuré

**Configuration actuelle** :
- ❌ Utilise `VITE_API_URL` (non défini)
- ❌ Fallback vers `http://localhost:3000/api` en production (incorrect)

**Impact** : Le dashboard ne peut pas communiquer avec le backend en production.

---

### ❌ Problème 3 : CORS Limité

**Configuration actuelle** :
- ⚠️ Autorise uniquement `localhost` (développement)
- ❌ Pas de configuration pour les apps iOS en production
- ❌ Pas de configuration pour le dashboard déployé

**Impact** : Les requêtes depuis les apps iOS et le dashboard peuvent être bloquées.

---

## ✅ Solution : Script de Correction Automatique

### 📝 Script Créé

**Fichier** : `scripts/corriger-integrations.sh`

Ce script corrige automatiquement :
1. ✅ URLs dans `Info.plist`
2. ✅ URLs dans `ConfigurationService.swift`
3. ✅ Configuration du dashboard (`.env.production`)
4. ✅ CORS dans Cloud Run

---

## 🚀 Utilisation

### Étape 1 : Exécuter le Script

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
./scripts/corriger-integrations.sh
```

### Étape 2 : Vérifier les Modifications

#### Vérifier Info.plist

```bash
grep "API_BASE_URL" "Tshiakani VTC/Info.plist"
# Devrait afficher : https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
```

#### Vérifier ConfigurationService.swift

```bash
grep "tshiakani-vtc-backend" "Tshiakani VTC/Services/ConfigurationService.swift"
# Devrait afficher la nouvelle URL
```

#### Vérifier .env.production

```bash
cat admin-dashboard/.env.production
# Devrait afficher :
# VITE_API_URL=https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
# VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

#### Tester le Backend

```bash
curl https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
# Devrait retourner : {"status":"OK",...}
```

---

## 📝 Modifications Effectuées

### 1. Info.plist

**Avant** :
```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api</string>
<key>WS_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app</string>
```

**Après** :
```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api</string>
<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend-418102154417.us-central1.run.app</string>
```

---

### 2. ConfigurationService.swift

**Avant** (lignes 46 et 76) :
```swift
return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
```

**Après** :
```swift
return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"
return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
```

---

### 3. Dashboard .env.production

**Créé** :
```env
# Configuration Production - Dashboard Admin
VITE_API_URL=https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

---

### 4. CORS Cloud Run

**Configuré** :
```bash
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
```

---

## ✅ Actions Après Correction

### 1. Rebuild l'App iOS

Dans Xcode :
1. Ouvrir le projet
2. Product > Clean Build Folder (⇧⌘K)
3. Product > Build (⌘B)
4. Tester la connexion

### 2. Redémarrer le Dashboard

```bash
cd admin-dashboard
npm run dev
```

Le dashboard devrait maintenant se connecter au backend Cloud Run.

### 3. Tester les Connexions

#### Test App Client iOS

1. Lancer l'app client
2. Tenter de se connecter
3. Vérifier que les requêtes arrivent au backend

#### Test App Driver iOS

1. Lancer l'app driver
2. Tenter de se connecter
3. Vérifier que les requêtes arrivent au backend

#### Test Dashboard

1. Ouvrir le dashboard dans le navigateur
2. Se connecter avec les identifiants admin
3. Vérifier que les données se chargent

---

## 🔍 Vérification des Connexions

### Vérifier les Logs Cloud Run

```bash
gcloud run services logs read tshiakani-vtc-backend \
  --region us-central1 \
  --project tshiakani-vtc-477711 \
  --limit 50
```

Vous devriez voir les requêtes entrantes depuis les apps iOS et le dashboard.

### Tester les Endpoints

#### Health Check

```bash
curl https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

#### Test Authentification (nécessite un token)

```bash
# Obtenir un token via l'app iOS, puis :
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/verify
```

---

## 📊 Résumé des URLs

### Backend Cloud Run

- **URL Base** : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app`
- **URL API** : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api`
- **URL WebSocket** : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app`

### Namespaces WebSocket

- **Client** : `/ws/client`
- **Driver** : `/ws/driver`

### Dashboard

- **API URL** : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api`
- **Admin API Key** : `aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8`

---

## ⚠️ Notes Importantes

1. **Sauvegardes** : Le script crée des sauvegardes automatiques avant modification
2. **CORS** : La configuration CORS peut prendre quelques minutes pour se propager
3. **Rebuild** : Il est nécessaire de rebuild l'app iOS après modification de `Info.plist`
4. **Dashboard** : Redémarrer le serveur de développement après création de `.env.production`

---

## 🎯 Résultat Attendu

Après exécution du script :

- ✅ **App Client iOS** : Se connecte au backend Cloud Run
- ✅ **App Driver iOS** : Se connecte au backend Cloud Run
- ✅ **Dashboard Frontend** : Se connecte au backend Cloud Run
- ✅ **CORS** : Autorise les requêtes depuis toutes les sources nécessaires

---

**Date de création** : 2025-01-15  
**Statut** : ✅ Script prêt à être exécuté

