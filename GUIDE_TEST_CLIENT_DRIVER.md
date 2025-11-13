# 🧪 Guide de Test - Communication Client ↔ Backend ↔ Driver

Ce guide explique comment tester la communication entre l'application Client, le Backend et l'application Driver.

---

## 📋 Vue d'Ensemble

Le script de test `test-client-driver-communication.js` simule le flux complet de communication entre un client et un driver via le backend:

1. **Authentification** : Client et Driver s'authentifient
2. **WebSocket** : Connexions WebSocket pour les communications temps réel
3. **Création de course** : Client crée une course
4. **Acceptation** : Driver accepte la course
5. **Suivi** : Client suit le driver en temps réel
6. **Mises à jour** : Driver met à jour sa position

---

## 🚀 Prérequis

### 1. Backend démarré

```bash
cd backend
npm run dev
```

Le backend doit être accessible sur `http://localhost:3000`

### 2. Base de données PostgreSQL

La base de données doit être accessible et configurée dans `backend/.env`

### 3. Dépendances installées

```bash
cd backend
npm install
```

---

## 🧪 Exécution du Test

### Méthode 1: Exécution directe

```bash
cd backend
node test-client-driver-communication.js
```

### Méthode 2: Avec variables d'environnement

```bash
cd backend
BASE_URL=http://localhost:3000 node test-client-driver-communication.js
```

---

## 📊 Tests Effectués

### Test 1: Authentification Client
- ✅ Client s'authentifie avec un numéro de téléphone
- ✅ Token JWT reçu

### Test 2: Authentification Driver
- ✅ Driver s'authentifie avec un numéro de téléphone
- ✅ Token JWT reçu

### Test 3: Connexion WebSocket Driver
- ✅ Driver se connecte au namespace `/ws/driver`
- ✅ Connexion WebSocket établie
- ✅ Écoute des événements `ride:request` et `ride:new`

### Test 4: Connexion WebSocket Client
- ✅ Client se connecte au namespace `/ws/client`
- ✅ Connexion WebSocket établie
- ✅ Écoute des événements `ride:status:changed`, `ride:accepted`, `driver:location:update`

### Test 5: Mise à jour Position Driver
- ✅ Driver met à jour sa position GPS
- ✅ Position sauvegardée en base de données
- ✅ Événement WebSocket `driver:location:update` émis

### Test 6: Création de Course
- ✅ Client estime le prix de la course
- ✅ Client crée une course
- ✅ Course sauvegardée en base de données
- ✅ Notification envoyée aux drivers proches

### Test 7: Acceptation de Course
- ✅ Driver accepte la course
- ✅ Course assignée au driver
- ✅ Statut de la course mis à jour
- ✅ Notification envoyée au client

### Test 8: Suivi du Driver
- ✅ Client suit la position du driver
- ✅ Données du driver récupérées (position, statut, ETA)

### Test 9: Mise à jour Position pendant la Course
- ✅ Driver met à jour sa position pendant la course
- ✅ Client reçoit les mises à jour de position

---

## 📈 Résultats Attendus

### Succès

Si tous les tests passent, vous devriez voir:

```
✅ Tests réussis: 9
❌ Tests échoués: 0
⚠️  Avertissements: 0

📈 Taux de réussite: 100.0%

✅ Tous les tests critiques sont passés!
✅ La communication Client ↔ Backend ↔ Driver fonctionne correctement!
```

### Échecs Possibles

#### Erreur: Backend non accessible
```
❌ Erreur lors de l'authentification client: connect ECONNREFUSED
```

**Solution**: Vérifiez que le backend est démarré sur le port 3000

#### Erreur: Base de données non accessible
```
❌ Erreur lors de la création de course: relation "rides" does not exist
```

**Solution**: Vérifiez que la base de données est créée et que les migrations sont exécutées

#### Erreur: WebSocket non connecté
```
❌ Timeout: Connexion WebSocket driver échouée
```

**Solution**: Vérifiez que Socket.io est configuré correctement dans le backend

---

## 🔍 Détails Techniques

### Routes API Testées

#### Client
- `POST /api/auth/signin` - Authentification
- `POST /api/rides/estimate-price` - Estimation du prix
- `POST /api/rides/create` - Création de course
- `GET /api/client/track_driver/:rideId` - Suivi du driver

#### Driver
- `POST /api/auth/signin` - Authentification
- `POST /api/driver/location/update` - Mise à jour position
- `POST /api/driver/accept_ride/:rideId` - Accepter une course

### Événements WebSocket Testés

#### Namespace Driver (`/ws/driver`)
- `ride:request` - Demande de course
- `ride:new` - Nouvelle course disponible

#### Namespace Client (`/ws/client`)
- `ride:status:changed` - Changement de statut de course
- `ride:accepted` - Course acceptée
- `driver:location:update` - Mise à jour de position du driver

---

## 🛠️ Dépannage

### Problème 1: Tests échouent avec "Token invalide"

**Cause**: Les tokens JWT expirent rapidement ou ne sont pas valides

**Solution**: Vérifiez que `JWT_SECRET` est configuré dans `backend/.env`

### Problème 2: WebSocket ne se connecte pas

**Cause**: Socket.io n'est pas configuré correctement ou CORS bloque les connexions

**Solution**: 
1. Vérifiez la configuration CORS dans `backend/server.postgres.js`
2. Vérifiez que Socket.io est correctement initialisé

### Problème 3: Course non créée

**Cause**: Erreur de validation ou problème de base de données

**Solution**:
1. Vérifiez les logs du backend
2. Vérifiez que les coordonnées GPS sont valides
3. Vérifiez que la base de données est accessible

### Problème 4: Driver ne reçoit pas les notifications

**Cause**: Le driver n'est pas en ligne ou n'est pas à proximité

**Solution**:
1. Vérifiez que le driver a mis à jour sa position
2. Vérifiez que le driver est connecté au WebSocket
3. Vérifiez les logs du backend pour les notifications

---

## 📝 Logs Détaillés

Le script affiche des logs détaillés pour chaque test:

```
═══════════════════════════════════════════════════════════════
TEST 1: Authentification Client
═══════════════════════════════════════════════════════════════
✅ Client authentifié avec succès
   Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

═══════════════════════════════════════════════════════════════
TEST 2: Authentification Driver
═══════════════════════════════════════════════════════════════
✅ Driver authentifié avec succès
   Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Les événements WebSocket sont également loggés:

```
📨 Driver reçoit une demande de course: {"rideId":123,"pickupLocation":{...}}
📨 Client reçoit une notification de course acceptée: {"rideId":123,"driverId":456}
```

---

## 🎯 Prochaines Étapes

Après avoir réussi tous les tests:

1. **Tester avec les applications iOS réelles**: Utilisez les applications Client et Driver pour tester en conditions réelles

2. **Tester les scénarios d'erreur**: Testez les cas d'erreur (driver indisponible, course annulée, etc.)

3. **Tester la performance**: Testez avec plusieurs clients et drivers simultanément

4. **Tester la scalabilité**: Testez avec un grand nombre de courses et de drivers

---

## 📚 Ressources

- [Documentation Backend](./backend/README.md)
- [Routes API](./backend/API_CLIENT_V1.md)
- [Configuration WebSocket](./backend/server.postgres.js)
- [Vérification des Connexions](./RAPPORT_VERIFICATION_CONNEXIONS.md)

---

**Dernière mise à jour**: $(date)

