# ⚡ Actions Immédiates - Guide Pratique

Guide pratique pour les actions immédiates avec votre adresse IP locale.

## 🎯 Votre Configuration

**Adresse IP locale:** `192.168.1.79`  
**Backend:** `http://192.168.1.79:3000`  
**API:** `http://192.168.1.79:3000/api`

---

## 1️⃣ Tester les Endpoints API (2 minutes)

### Script Automatique

```bash
cd backend
./scripts/test-api.sh
```

### Test Manuel

```bash
# Health check
curl http://localhost:3000/health

# Test d'authentification
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000000", "name": "Test User"}'
```

---

## 2️⃣ Connecter l'Application iOS (5 minutes)

### Option A: Configuration via UserDefaults (Recommandé)

1. **Ouvrir l'app iOS** dans Xcode
2. **Lancer l'app** sur le simulateur
3. **Aller dans les paramètres** de l'app
4. **Trouver "Configuration Backend"**
5. **Configurer:**
   - **API Base URL:** `http://192.168.1.79:3000/api`
   - **Socket Base URL:** `http://192.168.1.79:3000`

### Option B: Modification du Code

**Fichier:** `Tshiakani VTC/Services/ConfigurationService.swift`

```swift
var apiBaseURL: String {
    #if DEBUG
    #if targetEnvironment(simulator)
    return "http://192.168.1.79:3000/api"  // ← Votre IP
    #else
    return "http://localhost:3000/api"
    #endif
    #else
    return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
    #endif
}

var socketBaseURL: String {
    #if DEBUG
    #if targetEnvironment(simulator)
    return "http://192.168.1.79:3000"  // ← Votre IP
    #else
    return "http://localhost:3000"
    #endif
    #else
    return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
    #endif
}
```

### Configurer CORS dans le Backend

**Mettre à jour:** `backend/.env`

```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.79:3000
```

**Ou utiliser le script:**
```bash
./SCRIPTS_ACTION_RAPIDE.sh config-cors
```

---

## 3️⃣ Connecter le Dashboard Admin (3 minutes)

### Configuration

**Créer le fichier:** `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
```

### Démarrer le Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

**Ou utiliser le script:**
```bash
./SCRIPTS_ACTION_RAPIDE.sh config-dashboard
```

**Le dashboard sera accessible sur:** `http://localhost:5173`

---

## 4️⃣ Configurer Cloud Storage (10 minutes)

### Script Automatique

```bash
cd backend
npm run setup:storage
```

**Ou utiliser le script:**
```bash
./SCRIPTS_ACTION_RAPIDE.sh setup-storage
```

### Vérification

```bash
cd backend
npm run verify:storage
```

---

## 5️⃣ Déployer sur Cloud Run (15 minutes)

### Script Automatique

```bash
./SCRIPTS_ACTION_RAPIDE.sh deploy
```

### Déploiement Manuel

```bash
cd backend
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

---

## 🚀 Commandes Rapides

### Tester l'API
```bash
cd backend && ./scripts/test-api.sh
```

### Configurer iOS
```bash
./SCRIPTS_ACTION_RAPIDE.sh config-ios
```

### Configurer Dashboard
```bash
./SCRIPTS_ACTION_RAPIDE.sh config-dashboard
```

### Configurer CORS
```bash
./SCRIPTS_ACTION_RAPIDE.sh config-cors
```

### Configurer Cloud Storage
```bash
./SCRIPTS_ACTION_RAPIDE.sh setup-storage
```

### Déployer
```bash
./SCRIPTS_ACTION_RAPIDE.sh deploy
```

---

## ✅ Checklist Rapide

### Immédiat (Maintenant)
- [ ] **Tester l'API:** `cd backend && ./scripts/test-api.sh`
- [ ] **Configurer iOS:** Utiliser l'IP `192.168.1.79` dans l'app
- [ ] **Configurer Dashboard:** `./SCRIPTS_ACTION_RAPIDE.sh config-dashboard`
- [ ] **Configurer CORS:** Ajouter `http://192.168.1.79:3000` dans `.env`

### Bientôt (Optionnel)
- [ ] **Configurer Cloud Storage:** `npm run setup:storage`
- [ ] **Déployer sur Cloud Run:** Quand vous êtes prêt

---

## 📚 Guides Complets

- **Guide iOS:** `GUIDE_CONNEXION_IOS.md`
- **Guide Dashboard:** `GUIDE_CONNEXION_DASHBOARD.md`
- **Guide Actions:** `GUIDE_ACTIONS_SUIVANTES.md`
- **Guide Déploiement:** `PROCHAINES_ETAPES_FINAL.md`

---

## 🎯 Prochaines Actions (Ordre Recommandé)

1. **Maintenant:** Tester l'API (`./scripts/test-api.sh`)
2. **Maintenant:** Configurer CORS pour iOS (`config-cors`)
3. **Maintenant:** Configurer le Dashboard (`config-dashboard`)
4. **Ensuite:** Tester la connexion iOS
5. **Ensuite:** Tester le Dashboard
6. **Plus tard:** Cloud Storage et Déploiement

---

**Date:** Novembre 2025  
**Version:** 1.0.0  
**IP Locale:** 192.168.1.79

