# 🧪 Guide de Test Complet - Tshiakani VTC

Guide complet pour tester toutes les fonctionnalités après configuration.

## ✅ Configuration Vérifiée

- ✅ **CORS configuré** avec l'IP locale `192.168.1.79`
- ✅ **Dashboard configuré** avec `.env.local`
- ✅ **iOS configuré** avec IP par défaut `192.168.1.79`
- ✅ **Backend prêt** à démarrer

---

## 🚀 Étape 1: Démarrer le Backend

```bash
cd backend
npm run dev
```

**Vérifier dans les logs:**
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: 3.6
🚀 Serveur démarré sur le port 3000
📡 WebSocket namespace /ws/driver disponible
📡 WebSocket namespace /ws/client disponible
```

---

## 🧪 Étape 2: Tester les Endpoints API

### 2.1 Health Check

```bash
curl http://localhost:3000/health
```

**Réponse attendue:**
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2025-11-10T..."
}
```

### 2.2 Test d'Authentification

```bash
# Créer un utilisateur
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "name": "Test User"
  }'
```

**Réponse attendue:**
```json
{
  "success": true,
  "message": "Code OTP envoyé",
  "userId": 1
}
```

### 2.3 Test des Routes (avec token)

**Obtenir un token d'abord, puis:**

```bash
# Récupérer les courses
curl -X GET http://localhost:3000/api/rides \
  -H "Authorization: Bearer YOUR_TOKEN"

# Récupérer les utilisateurs
curl -X GET http://localhost:3000/api/users \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2.4 Script de Test Automatique

```bash
cd backend
./scripts/test-api.sh
```

---

## 📱 Étape 3: Tester l'Application iOS

### 3.1 Configuration

**Option A: Via UserDefaults (Recommandé)**
1. Ouvrir l'app iOS dans Xcode
2. Lancer l'app sur le simulateur
3. Aller dans les paramètres
4. Configuration Backend
5. Configurer:
   - **API Base URL:** `http://192.168.1.79:3000/api`
   - **Socket Base URL:** `http://192.168.1.79:3000`

**Option B: IP par défaut**
L'app utilise déjà `http://192.168.1.79:3000/api` par défaut sur appareil réel.

### 3.2 Tests dans l'App

1. **Test de connexion:**
   - Aller dans les paramètres
   - Tester la connexion backend
   - Vérifier que la connexion réussit

2. **Test d'authentification:**
   - Se connecter avec un numéro de téléphone
   - Vérifier que l'authentification fonctionne

3. **Test de création de course:**
   - Créer une course
   - Vérifier que la course est créée
   - Vérifier que les drivers sont notifiés

4. **Test WebSocket:**
   - Vérifier que la connexion WebSocket fonctionne
   - Vérifier que les mises à jour temps réel fonctionnent

---

## 🎨 Étape 4: Tester le Dashboard Admin

### 4.1 Démarrer le Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

**Le dashboard sera accessible sur:** `http://localhost:5173`

### 4.2 Tests dans le Dashboard

1. **Connexion:**
   - Ouvrir `http://localhost:5173`
   - Se connecter avec un numéro de téléphone admin
   - Vérifier que la connexion réussit

2. **Dashboard:**
   - Vérifier que les statistiques s'affichent
   - Vérifier que les graphiques fonctionnent

3. **Courses:**
   - Vérifier que la liste des courses s'affiche
   - Vérifier que les filtres fonctionnent
   - Vérifier que les détails s'affichent

4. **Utilisateurs:**
   - Vérifier que la liste des utilisateurs s'affiche
   - Vérifier que les actions fonctionnent

5. **Carte:**
   - Vérifier que la carte s'affiche
   - Vérifier que les conducteurs s'affichent
   - Vérifier que les courses actives s'affichent

---

## 🔗 Étape 5: Tester les Intégrations

### 5.1 Test Client → Backend

1. **Créer une course depuis l'app iOS**
2. **Vérifier dans le dashboard** que la course apparaît
3. **Vérifier dans les logs backend** que la course est créée

### 5.2 Test Driver → Backend

1. **Accepter une course depuis l'app Driver**
2. **Vérifier dans le dashboard** que le statut change
3. **Vérifier dans l'app Client** que le driver est assigné

### 5.3 Test WebSocket Temps Réel

1. **Créer une course depuis l'app Client**
2. **Vérifier que les drivers reçoivent la notification**
3. **Accepter la course depuis l'app Driver**
4. **Vérifier que le client reçoit la mise à jour**

### 5.4 Test Dashboard → Backend

1. **Modifier une course depuis le dashboard**
2. **Vérifier que la modification est sauvegardée**
3. **Vérifier que les apps reçoivent la mise à jour**

---

## ✅ Checklist de Tests

### Backend
- [ ] Health check réussi
- [ ] Authentification fonctionnelle
- [ ] Création de course fonctionnelle
- [ ] WebSocket fonctionnel
- [ ] Notifications fonctionnelles
- [ ] Base de données fonctionnelle

### Application iOS
- [ ] Connexion backend réussie
- [ ] Authentification fonctionnelle
- [ ] Création de course fonctionnelle
- [ ] WebSocket fonctionnel
- [ ] Mises à jour temps réel fonctionnelles
- [ ] Géolocalisation fonctionnelle

### Dashboard Admin
- [ ] Connexion réussie
- [ ] Statistiques affichées
- [ ] Liste des courses affichée
- [ ] Liste des utilisateurs affichée
- [ ] Carte fonctionnelle
- [ ] Actions fonctionnelles

### Intégrations
- [ ] Client → Backend fonctionnel
- [ ] Driver → Backend fonctionnel
- [ ] Dashboard → Backend fonctionnel
- [ ] WebSocket temps réel fonctionnel
- [ ] Notifications fonctionnelles

---

## 🐛 Dépannage

### Erreur: "Cannot connect to server"

**Solutions:**
1. Vérifier que le backend est démarré
2. Vérifier l'URL dans ConfigurationService
3. Vérifier que CORS autorise votre IP
4. Vérifier le firewall

### Erreur: "CORS policy"

**Solution:**
```bash
# Vérifier CORS dans .env
cat backend/.env | grep CORS_ORIGIN

# Ajouter votre IP si nécessaire
./scripts/configurer-tout.sh
```

### Erreur: "401 Unauthorized"

**Solutions:**
1. Vérifier que vous êtes authentifié
2. Vérifier que le token est valide
3. Vérifier que le token est envoyé dans les headers

---

## 📊 Résultats Attendus

### Backend
- ✅ Serveur démarré sur le port 3000
- ✅ Base de données connectée
- ✅ WebSocket actif
- ✅ Tous les endpoints fonctionnels

### Application iOS
- ✅ Connexion backend réussie
- ✅ Authentification fonctionnelle
- ✅ Création de course fonctionnelle
- ✅ WebSocket fonctionnel

### Dashboard Admin
- ✅ Dashboard accessible
- ✅ Connexion réussie
- ✅ Données affichées
- ✅ Fonctionnalités opérationnelles

---

## 🎉 Résultat Final

Une fois tous les tests réussis, vous aurez:

- ✅ Backend opérationnel
- ✅ Application iOS connectée
- ✅ Dashboard admin connecté
- ✅ WebSocket temps réel fonctionnel
- ✅ Toutes les intégrations fonctionnelles

**Votre système est prêt pour le développement et les tests !** 🚀

---

**Date:** Novembre 2025  
**Version:** 1.0.0

