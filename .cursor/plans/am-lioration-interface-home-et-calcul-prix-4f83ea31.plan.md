<!-- 4f83ea31-365c-42e6-a487-b6365442ccd4 dc839f33-ca40-41c5-984e-66092872d975 -->
# Plan : Implémentation Backend - Méthodes de Paiement pour App Driver

## Objectif

Ajouter le support complet des méthodes de paiement (M-Pesa, Orange Money) dans les endpoints backend pour l'application Driver, permettant aux conducteurs de voir et gérer les méthodes de paiement des courses.

## Modifications Backend

### 1. Ajouter endpoint GET pour détails de course

**Fichier** : `backend/routes.postgres/driver.js`

- Créer `GET /api/driver/rides/:rideId` pour récupérer tous les détails d'une course
- Inclure `paymentMethod` dans la réponse avec support des nouvelles valeurs (`mpesa`, `orange_money`)
- Vérifier que le conducteur est bien assigné à la course
- Retourner les informations complètes : pickup/dropoff, prix, méthode de paiement, client, etc.

**Structure de réponse** :

```javascript
{
  id: ride.id,
  status: ride.status,
  pickupLocation: {...},
  dropoffLocation: {...},
  estimatedPrice: ride.estimatedPrice,
  finalPrice: ride.finalPrice,
  paymentMethod: ride.paymentMethod, // 'cash', 'mpesa', 'orange_money', etc.
  client: {...},
  ...
}
```

### 2. Enrichir la réponse de accept_ride

**Fichier** : `backend/routes.postgres/driver.js` (ligne ~265 et ~354)

- Modifier `POST /api/driver/accept_ride/:rideId` pour inclure `paymentMethod` dans la réponse
- Ajouter `paymentMethod` dans les deux branches de réponse (service temps réel et fallback transaction)

**Modifications** :

- Ligne ~265 : Ajouter `paymentMethod: updatedRide.paymentMethod` dans la réponse
- Ligne ~354 : Ajouter `paymentMethod: rideInTransaction.paymentMethod` dans la réponse

### 3. Enrichir la réponse de complete_ride

**Fichier** : `backend/routes.postgres/driver.js` (ligne ~700+)

- Vérifier que `POST /api/driver/complete_ride/:rideId` retourne `paymentMethod` dans la réponse finale
- S'assurer que la méthode de paiement (choisie par le client ou modifiée par le driver) est bien retournée

### 4. Vérifier la validation des méthodes de paiement

**Fichier** : `backend/routes.postgres/driver.js` (ligne 533)

- Confirmer que la validation accepte bien `'mpesa'` et `'orange_money'` (déjà fait précédemment)
- Vérifier que toutes les valeurs sont cohérentes avec le modèle `PaymentMethod` côté client

## Tests à effectuer

1. Tester `GET /api/driver/rides/:rideId` avec différentes méthodes de paiement
2. Vérifier que `accept_ride` retourne bien `paymentMethod`
3. Vérifier que `complete_ride` accepte et retourne correctement les nouvelles méthodes
4. Tester avec les valeurs : `cash`, `mpesa`, `orange_money`, `stripe`

## Fichiers à modifier

- `backend/routes.postgres/driver.js` : Ajouter endpoint GET et enrichir les réponses existantes