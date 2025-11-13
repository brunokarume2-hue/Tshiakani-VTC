# 🧪 Instructions - Test de Communication Client ↔ Driver

## ✅ Ce qui a été créé

Un script de test complet pour vérifier que l'application Client et l'application Driver communiquent correctement via le backend.

---

## 🚀 Étapes pour Exécuter le Test

### Étape 1: Installer les Dépendances

```bash
cd backend
npm install
```

Cela installera `socket.io-client` (ajouté aux dépendances).

### Étape 2: Démarrer le Backend

```bash
cd backend
npm run dev
```

Le backend doit être accessible sur `http://localhost:3000`

### Étape 3: Exécuter le Test

```bash
cd backend
npm run test:client-driver
```

Ou directement:

```bash
cd backend
node test-client-driver-communication.js
```

---

## 📊 Tests Effectués

Le script teste les 9 scénarios suivants:

1. ✅ **Authentification Client** - Client s'authentifie et reçoit un token JWT
2. ✅ **Authentification Driver** - Driver s'authentifie et reçoit un token JWT
3. ✅ **Connexion WebSocket Driver** - Driver se connecte au namespace `/ws/driver`
4. ✅ **Connexion WebSocket Client** - Client se connecte au namespace `/ws/client`
5. ✅ **Mise à jour Position Driver** - Driver met à jour sa position GPS
6. ✅ **Création de Course** - Client crée une course
7. ✅ **Acceptation de Course** - Driver accepte la course
8. ✅ **Suivi du Driver** - Client suit la position du driver
9. ✅ **Mise à jour Position pendant Course** - Driver met à jour sa position pendant la course

---

## 📋 Résultats Attendus

### Succès

Si tous les tests passent, vous verrez:

```
✅ Tests réussis: 9
❌ Tests échoués: 0
⚠️  Avertissements: 0

📈 Taux de réussite: 100.0%

✅ Tous les tests critiques sont passés!
✅ La communication Client ↔ Backend ↔ Driver fonctionne correctement!
```

### Exemple de Logs

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

═══════════════════════════════════════════════════════════════
TEST 6: Client crée une course
═══════════════════════════════════════════════════════════════
✅ Prix estimé: 5000 CDF
✅ Course créée avec succès
   ID de la course: 123
   Statut: pending

📨 Driver reçoit une demande de course: {"rideId":123,...}

═══════════════════════════════════════════════════════════════
TEST 7: Driver accepte la course
═══════════════════════════════════════════════════════════════
✅ Course acceptée avec succès
   ID de la course: 123
   Statut: accepted

📨 Client reçoit une notification de course acceptée: {"rideId":123,...}
```

---

## 🔍 Ce qui est Vérifié

### Communication REST API

- ✅ Client crée une course via `POST /api/rides/create`
- ✅ Driver accepte la course via `POST /api/driver/accept_ride/:rideId`
- ✅ Client suit le driver via `GET /api/client/track_driver/:rideId`
- ✅ Driver met à jour sa position via `POST /api/driver/location/update`

### Communication WebSocket

- ✅ Driver reçoit les notifications de nouvelles courses via `/ws/driver`
- ✅ Client reçoit les notifications de course acceptée via `/ws/client`
- ✅ Client reçoit les mises à jour de position du driver via `/ws/client`

### Flux Complet

1. **Client crée une course** → Backend sauvegarde en base de données
2. **Backend notifie les drivers** → Notification WebSocket envoyée aux drivers proches
3. **Driver accepte la course** → Backend met à jour la course et notifie le client
4. **Client suit le driver** → Backend retourne la position et le statut du driver
5. **Driver met à jour sa position** → Backend notifie le client via WebSocket

---

## ⚠️ Prérequis

### 1. Backend Démarré
```bash
cd backend
npm run dev
```

### 2. Base de Données PostgreSQL
La base de données doit être accessible et configurée dans `backend/.env`

### 3. Dépendances Installées
```bash
cd backend
npm install
```

---

## 🛠️ Dépannage

### Erreur: "Cannot find module 'socket.io-client'"

**Solution**: Installez les dépendances:
```bash
cd backend
npm install
```

### Erreur: "Backend non accessible"

**Solution**: Vérifiez que le backend est démarré:
```bash
cd backend
npm run dev
```

Vérifiez également que le backend est accessible sur `http://localhost:3000`

### Erreur: "Base de données non accessible"

**Solution**: 
1. Vérifiez la configuration dans `backend/.env`
2. Vérifiez que PostgreSQL est en cours d'exécution
3. Testez la connexion avec: `cd backend && node test-database-connection.js`

### Erreur: "WebSocket ne se connecte pas"

**Solution**: 
1. Vérifiez la configuration CORS dans `backend/server.postgres.js`
2. Vérifiez que Socket.io est correctement initialisé
3. Vérifiez les logs du backend pour les erreurs

### Erreur: "Course non créée"

**Solution**:
1. Vérifiez les logs du backend
2. Vérifiez que les coordonnées GPS sont valides
3. Vérifiez que la base de données est accessible
4. Vérifiez que les tables existent en base de données

---

## 📝 Notes Importantes

- Les tests utilisent des numéros de téléphone de test: `+243900000001` (client) et `+243900000002` (driver)
- Les coordonnées GPS utilisées sont pour Kinshasa, RD Congo
- Les tests créent des courses réelles en base de données (à nettoyer si nécessaire)
- Les connexions WebSocket sont fermées automatiquement à la fin des tests
- Le script affiche des logs détaillés pour chaque étape du test

---

## 📚 Fichiers Créés

1. **`backend/test-client-driver-communication.js`** - Script de test principal
2. **`GUIDE_TEST_CLIENT_DRIVER.md`** - Guide d'utilisation détaillé
3. **`RESUME_TEST_CLIENT_DRIVER.md`** - Résumé du test
4. **`INSTRUCTIONS_TEST_CLIENT_DRIVER.md`** - Instructions (ce fichier)
5. **Script npm ajouté** - `npm run test:client-driver` dans `package.json`

---

## 🎯 Prochaines Étapes

Après avoir réussi tous les tests:

1. **Tester avec les applications iOS réelles** - Utilisez les applications Client et Driver pour tester en conditions réelles
2. **Tester les scénarios d'erreur** - Testez les cas d'erreur (driver indisponible, course annulée, etc.)
3. **Tester la performance** - Testez avec plusieurs clients et drivers simultanément
4. **Tester la scalabilité** - Testez avec un grand nombre de courses et de drivers

---

## ✅ Conclusion

Le script de test vérifie que:
- ✅ Le backend est accessible
- ✅ Les routes API fonctionnent correctement
- ✅ Les connexions WebSocket sont établies
- ✅ La communication entre Client et Driver fonctionne via le backend
- ✅ Les notifications sont envoyées et reçues correctement
- ✅ Le flux complet de création et acceptation de course fonctionne

**Exécutez le test pour vérifier que tout fonctionne correctement!**

---

**Dernière mise à jour**: $(date)

