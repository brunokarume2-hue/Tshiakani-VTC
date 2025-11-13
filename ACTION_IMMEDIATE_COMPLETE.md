# 🚀 Action Immédiate Complète - Tshiakani VTC

Guide complet pour toutes les actions immédiates avec vos informations spécifiques.

## 🎯 Votre Configuration

- **Adresse IP locale:** `192.168.1.79`
- **Backend local:** `http://192.168.1.79:3000`
- **API local:** `http://192.168.1.79:3000/api`
- **Dashboard local:** `http://localhost:5173`

---

## ✅ Étape 1: Tester les Endpoints API

### 1.1 Démarrer le Serveur

```bash
cd backend
npm run dev
```

### 1.2 Tester dans un Nouveau Terminal

```bash
# Health check
curl http://localhost:3000/health

# Test des endpoints
cd backend
./scripts/test-api.sh
```

**Résultat attendu:**
```json
{"status":"OK","database":"connected","timestamp":"..."}
```

---

## ✅ Étape 2: Connecter l'Application iOS

### 2.1 Configuration dans l'App iOS

**Option A: Via UserDefaults (Recommandé)**

1. Ouvrir l'app iOS dans Xcode
2. Lancer l'app
3. Aller dans les paramètres de l'app
4. Trouver "Configuration Backend"
5. Configurer:
   - **API Base URL:** `http://192.168.1.79:3000/api`
   - **Socket Base URL:** `http://192.168.1.79:3000`

**Option B: Modification du Code**

**Fichier:** `Tshiakani VTC/Services/ConfigurationService.swift`

Modifier les lignes 25-26 et 44-45:

```swift
#if DEBUG
#if targetEnvironment(simulator)
return "http://192.168.1.79:3000/api"  // ← Votre IP
#else
return "http://localhost:3000/api"
#endif
```

### 2.2 Configurer CORS dans le Backend

**Fichier:** `backend/.env`

Ajouter ou modifier la ligne `CORS_ORIGIN`:

```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.79:3000
```

**Redémarrer le serveur après modification:**
```bash
cd backend
npm run dev
```

### 2.3 Tester la Connexion

Dans l'app iOS:
1. Aller dans les paramètres
2. Tester la connexion backend
3. Vérifier que la connexion réussit

---

## ✅ Étape 3: Connecter le Dashboard Admin

### 3.1 Configuration

**Créer le fichier:** `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
```

### 3.2 Démarrer le Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

**Le dashboard sera accessible sur:** `http://localhost:5173`

### 3.3 Tester la Connexion

1. Ouvrir `http://localhost:5173`
2. Se connecter avec un numéro de téléphone admin
3. Vérifier que les données s'affichent

---

## ✅ Étape 4: Configurer Cloud Storage (Optionnel)

### 4.1 Configuration

```bash
cd backend
npm run setup:storage
```

### 4.2 Vérification

```bash
cd backend
npm run verify:storage
```

---

## ✅ Étape 5: Déployer sur Cloud Run (Optionnel)

### 5.1 Déploiement

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

### Scripts Disponibles

```bash
# Tester l'API
cd backend && ./scripts/test-api.sh

# Configurer iOS (affiche l'IP)
./SCRIPTS_ACTION_RAPIDE.sh config-ios

# Configurer Dashboard
./SCRIPTS_ACTION_RAPIDE.sh config-dashboard

# Configurer CORS
./SCRIPTS_ACTION_RAPIDE.sh config-cors

# Configurer Cloud Storage
./SCRIPTS_ACTION_RAPIDE.sh setup-storage

# Déployer
./SCRIPTS_ACTION_RAPIDE.sh deploy
```

---

## 📋 Checklist Complète

### Immédiat (Faire Maintenant)

- [ ] **Démarrer le serveur:** `cd backend && npm run dev`
- [ ] **Tester l'API:** `./scripts/test-api.sh`
- [ ] **Configurer CORS:** Ajouter `http://192.168.1.79:3000` dans `.env`
- [ ] **Configurer iOS:** Utiliser l'IP `192.168.1.79` dans l'app
- [ ] **Configurer Dashboard:** Créer `.env.local` et démarrer

### Tests

- [ ] **Test API:** Health check réussi
- [ ] **Test iOS:** Connexion réussie depuis l'app
- [ ] **Test Dashboard:** Dashboard accessible et fonctionnel
- [ ] **Test Authentification:** Connexion réussie
- [ ] **Test Création Course:** Création de course réussie

### Optionnel (Plus Tard)

- [ ] **Cloud Storage:** Configuré et testé
- [ ] **Déploiement Cloud Run:** Déployé et testé
- [ ] **CI/CD:** GitHub Actions configuré
- [ ] **Monitoring:** Cloud Monitoring configuré
- [ ] **Secret Manager:** Secrets migrés

---

## 🎯 Ordre d'Exécution Recommandé

1. **Maintenant (5 min):**
   - Démarrer le serveur (`npm run dev`)
   - Tester l'API (`./scripts/test-api.sh`)
   - Configurer CORS (ajouter IP dans `.env`)

2. **Ensuite (10 min):**
   - Configurer iOS (IP `192.168.1.79`)
   - Configurer Dashboard (`.env.local`)
   - Tester les connexions

3. **Plus tard (Optionnel):**
   - Cloud Storage
   - Déploiement Cloud Run
   - CI/CD et Monitoring

---

## 📚 Documentation

- **Guide iOS:** `GUIDE_CONNEXION_IOS.md`
- **Guide Dashboard:** `GUIDE_CONNEXION_DASHBOARD.md`
- **Guide Actions:** `GUIDE_ACTIONS_SUIVANTES.md`
- **Actions Immédiates:** `ACTIONS_IMMEDIATES.md`
- **Prochaines Étapes:** `PROCHAINES_ETAPES_FINAL.md`

---

## 🎉 Résumé

**Configuration prête:**
- ✅ Backend configuré et fonctionnel
- ✅ Base de données connectée
- ✅ Services actifs
- ✅ Documentation complète

**Actions immédiates:**
1. Démarrer le serveur
2. Configurer iOS avec IP `192.168.1.79`
3. Configurer Dashboard
4. Tester les connexions

**Tout est prêt ! Commencez maintenant ! 🚀**

---

**Date:** Novembre 2025  
**Version:** 1.0.0  
**IP Locale:** 192.168.1.79

