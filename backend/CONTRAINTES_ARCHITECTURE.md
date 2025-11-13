# 🛡️ Contraintes d'Architecture - Tshiakani VTC

Ce document décrit les contraintes d'architecture critiques implémentées dans le backend.

## 📋 Table des Matières

1. [Transactions ACID](#a-transactions-acid)
2. [Sécurité des Coordonnées (Géofencing)](#b-sécurité-des-coordonnées-géofencing)
3. [Sécurité et Tokens](#c-sécurité-et-tokens)

---

## A. Transactions ACID

### 🎯 Principe

Toute opération modifiant le statut d'une course et la disponibilité d'un chauffeur doit être enveloppée dans une transaction PostgreSQL pour garantir l'atomicité.

### ✅ Implémentation

**Service**: `backend/services/TransactionService.js`

#### 1. Acceptation de Course

```javascript
await TransactionService.acceptRideWithTransaction(
  rideId,
  driverId,
  driverLocation,
  pickupLocation,
  maxDistanceMeters
);
```

**Opérations atomiques** :
- ✅ Mise à jour du statut de la course à `'accepted'`
- ✅ Attribution du chauffeur à la course
- ✅ Mise à jour du statut du chauffeur (isOnline, currentRideId)
- ✅ Vérification de la proximité (géofencing)

**Rollback automatique** en cas d'erreur.

#### 2. Complétion de Course

```javascript
await TransactionService.completeRideWithTransaction(
  rideId,
  finalPrice,
  paymentToken
);
```

**Opérations atomiques** :
- ✅ Mise à jour du statut de la course à `'completed'`
- ✅ Mise à jour du statut du chauffeur à `'disponible'`
- ✅ Création de la transaction de paiement dans la table `transactions`

**Rollback automatique** si une opération échoue.

#### 3. Annulation de Course

```javascript
await TransactionService.cancelRideWithTransaction(
  rideId,
  reason
);
```

**Opérations atomiques** :
- ✅ Mise à jour du statut de la course à `'cancelled'`
- ✅ Remise du chauffeur disponible si nécessaire

---

## B. Sécurité des Coordonnées (Géofencing)

### 🎯 Principe

Avant de permettre à un chauffeur de prendre une course, l'API vérifie que la position actuelle du chauffeur est raisonnablement proche du point de départ désigné par le client.

**But** : Empêcher la fraude et les annulations tardives.

### ✅ Implémentation

**Middleware**: `backend/middlewares.postgres/geofencing.js`

#### Utilisation de ST_DWithin (PostGIS)

```javascript
const { verifyDriverProximityWithST_DWithin } = require('../middlewares.postgres/geofencing');

router.put('/accept/:courseId', 
  auth, 
  verifyDriverProximityWithST_DWithin(2000), // 2000m = 2km
  async (req, res) => {
    // ...
  }
);
```

#### Vérification

1. **Récupération de la position du chauffeur** depuis `req.body.driverLocation`
2. **Récupération du point de départ** depuis la course ou `req.body.pickupLocation`
3. **Calcul de distance** avec `ST_DWithin` de PostGIS
4. **Validation** : Distance doit être ≤ 2000m (configurable)

#### Exemple de Requête PostGIS

```sql
SELECT ST_DWithin(
  ST_MakePoint($1, $2)::geography,  -- Position chauffeur
  ST_MakePoint($3, $4)::geography,  -- Point de départ
  $5                                  -- Distance max (mètres)
) AS is_within_range
```

#### Réponse d'Erreur

Si le chauffeur est trop éloigné :

```json
{
  "error": "Le chauffeur est trop éloigné du point de départ",
  "details": {
    "distance": 3500,
    "maxAllowed": 2000,
    "distanceKm": "3.50"
  }
}
```

---

## C. Sécurité et Tokens

### 🎯 Principe

L'application iOS ne doit **jamais** envoyer :
- ❌ Mot de passe en clair
- ❌ Informations bancaires (numéro de carte, CVV, etc.)

L'API utilise uniquement :
- ✅ **Tokens JWT** pour l'authentification
- ✅ **Tokens de paiement** générés côté client (Stripe, etc.)

### ✅ Implémentation

#### 1. Authentification JWT

**Middleware**: `backend/middlewares.postgres/auth.js`

```javascript
const { auth } = require('../middlewares.postgres/auth');

router.post('/create', auth, async (req, res) => {
  // req.user contient l'utilisateur authentifié
  // req.userId contient l'ID de l'utilisateur
});
```

**Fonctionnement** :
1. Le client envoie le token JWT dans le header `Authorization: Bearer <token>`
2. Le middleware vérifie et décode le token
3. L'utilisateur est attaché à `req.user`

**⚠️ Important** : Le mot de passe n'est jamais envoyé après l'authentification initiale.

#### 2. Tokens de Paiement

**Service**: `backend/services/PaymentService.js`

```javascript
await PaymentService.processPayment(
  rideId,
  amount,
  paymentToken  // Token généré côté client par Stripe/Prestataire
);
```

**Flux sécurisé** :

1. **Côté Client (iOS)** :
   ```swift
   // Générer un token de paiement avec Stripe SDK
   let paymentToken = try await stripeClient.createPaymentToken(cardDetails)
   ```

2. **Envoi à l'API** :
   ```json
   {
     "rideId": 123,
     "amount": 5000.00,
     "paymentToken": "tok_visa_1234..."  // Token uniquement, pas les infos bancaires
   }
   ```

3. **Côté Serveur** :
   - Validation du token avec le prestataire (Stripe, etc.)
   - Création de la transaction dans la base de données
   - Aucune information bancaire stockée

#### 3. Validation des Tokens

```javascript
await PaymentService.validatePaymentToken(paymentToken, amount);
```

**Vérifications** :
- ✅ Token non vide et format valide
- ✅ Token non expiré
- ✅ Token non déjà utilisé
- ✅ Montant cohérent

---

## 📝 Exemples d'Utilisation

### Route avec Toutes les Contraintes

```javascript
// Accepter une course avec géofencing et transaction ACID
router.put('/accept/:courseId', 
  auth,                                    // 1. Authentification JWT
  [
    body('driverLocation.latitude').isFloat(),
    body('driverLocation.longitude').isFloat()
  ],
  verifyDriverProximityWithST_DWithin(2000), // 2. Géofencing
  async (req, res) => {
    try {
      // 3. Transaction ACID
      const ride = await TransactionService.acceptRideWithTransaction(
        parseInt(req.params.courseId),
        req.user.id,
        req.body.driverLocation,
        pickupLocation,
        2000
      );
      
      res.json(ride);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);
```

### Terminer une Course avec Paiement

```javascript
router.put('/complete/:courseId', 
  auth,
  [
    body('finalPrice').isFloat(),
    body('paymentToken').notEmpty()  // Token de paiement (pas d'infos bancaires)
  ],
  async (req, res) => {
    try {
      // Transaction ACID : course + chauffeur + transaction de paiement
      const result = await TransactionService.completeRideWithTransaction(
        parseInt(req.params.courseId),
        req.body.finalPrice,
        req.body.paymentToken  // Token uniquement
      );
      
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);
```

---

## 🔒 Checklist de Sécurité

Avant de déployer, vérifiez :

- [ ] Toutes les opérations critiques utilisent `TransactionService`
- [ ] Le géofencing est activé sur les routes d'acceptation
- [ ] Les tokens JWT sont validés sur toutes les routes protégées
- [ ] Aucun mot de passe n'est stocké en clair
- [ ] Les tokens de paiement sont validés avant traitement
- [ ] Les informations bancaires ne sont jamais stockées
- [ ] Les transactions sont rollback en cas d'erreur

---

## 🚀 Migration depuis l'Ancien Code

Pour migrer vos routes existantes :

1. **Remplacer les opérations manuelles** par `TransactionService`
2. **Ajouter le middleware de géofencing** sur les routes d'acceptation
3. **Vérifier que les tokens de paiement** sont utilisés au lieu des infos bancaires

Exemple :

```javascript
// ❌ Ancien code (non sécurisé)
ride.status = 'accepted';
await rideRepository.save(ride);
driver.driverInfo.isOnline = false;
await userRepository.save(driver);

// ✅ Nouveau code (sécurisé avec transaction ACID)
await TransactionService.acceptRideWithTransaction(
  rideId, driverId, driverLocation, pickupLocation, 2000
);
```

---

## 📚 Références

- [PostgreSQL Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [PostGIS ST_DWithin](https://postgis.net/docs/ST_DWithin.html)
- [JWT Authentication](https://jwt.io/)
- [Stripe Payment Tokens](https://stripe.com/docs/payments/tokens)

