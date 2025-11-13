# 🔴 Structure de Données Redis - Tshiakani VTC

## 🎯 Vue d'Ensemble

Redis est utilisé pour le suivi temps réel des conducteurs avec mise à jour de position toutes les 2-3 secondes.

---

## 📊 Structure des Données

### Clé: `driver:<driver_id>`

**Format**: Hash Redis

**Exemple**: `driver:4523`

**Champs (Hash):**

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `lat` | String | Latitude actuelle | `"-4.3276"` |
| `lon` | String | Longitude actuelle | `"15.3136"` |
| `status` | String | Statut du conducteur | `"available"` |
| `last_update` | String | Dernier horodatage (ISO 8601) | `"2025-01-15T10:30:00Z"` |
| `current_ride_id` | String | ID de la course actuelle | `"123"` ou `""` |
| `heading` | String | Direction en degrés (0-360) | `"90"` |
| `speed` | String | Vitesse en km/h | `"45"` |

**TTL (Time To Live):** 300 secondes (5 minutes)

---

## 🔄 Opérations Redis

### 1. Mettre à Jour la Position

**Commande:**
```redis
HSET driver:4523 lat "-4.3276" lon "15.3136" status "available" last_update "2025-01-15T10:30:00Z" current_ride_id "" heading "90" speed "45"
EXPIRE driver:4523 300
```

**Via Service:**
```javascript
await redisService.updateDriverLocation(4523, {
  latitude: -4.3276,
  longitude: 15.3136,
  status: 'available',
  heading: 90,
  speed: 45
});
```

---

### 2. Mettre à Jour le Statut

**Commande:**
```redis
HSET driver:4523 status "in_progress" current_ride_id "123" last_update "2025-01-15T10:35:00Z"
EXPIRE driver:4523 300
```

**Via Service:**
```javascript
await redisService.updateDriverStatus(4523, 'in_progress', 123);
```

---

### 3. Récupérer les Informations

**Commande:**
```redis
HGETALL driver:4523
```

**Via Service:**
```javascript
const driver = await redisService.getDriverLocation(4523);
// Retourne: { driverId: 4523, latitude: -4.3276, longitude: 15.3136, status: 'available', ... }
```

---

### 4. Récupérer Tous les Conducteurs Disponibles

**Commande:**
```redis
KEYS driver:*
HGETALL driver:4523
HGETALL driver:4524
...
```

**Via Service:**
```javascript
const drivers = await redisService.getAvailableDrivers();
// Retourne: [{ driverId: 4523, latitude: -4.3276, ... }, ...]
```

---

### 5. Supprimer un Conducteur (Déconnexion)

**Commande:**
```redis
DEL driver:4523
```

**Via Service:**
```javascript
await redisService.removeDriver(4523);
```

---

### 6. Vérifier si un Conducteur est en Ligne

**Commande:**
```redis
EXISTS driver:4523
```

**Via Service:**
```javascript
const isOnline = await redisService.isDriverOnline(4523);
// Retourne: true ou false
```

---

## 📋 Statuts des Conducteurs

| Statut | Description | Utilisation |
|--------|-------------|-------------|
| `available` | Conducteur disponible | Prêt à accepter des courses |
| `en_route_to_pickup` | En route vers le point de départ | Course acceptée, en route |
| `in_progress` | Course en cours | Transport du client |
| `offline` | Conducteur hors ligne | Déconnecté |

---

## ⏱️ Fréquence de Mise à Jour

### Mise à Jour de Position

**Fréquence:** Toutes les 2-3 secondes

**Depuis l'application conducteur:**
```javascript
// Mettre à jour la position toutes les 2-3 secondes
setInterval(async () => {
  await updateDriverLocation({
    driverId: currentDriverId,
    latitude: currentLocation.latitude,
    longitude: currentLocation.longitude,
    status: currentStatus,
    heading: currentHeading,
    speed: currentSpeed
  });
}, 2000); // 2 secondes
```

### TTL (Time To Live)

**Durée:** 5 minutes (300 secondes)

**Raison:** Si un conducteur ne met pas à jour sa position pendant 5 minutes, les données expirent automatiquement.

**Renouvellement:** Chaque mise à jour renouvelle le TTL à 5 minutes.

---

## 🔍 Recherche de Conducteurs Proches

### Stratégie Hybride (Redis + PostGIS)

1. **Récupérer depuis Redis** (rapide)
   - Tous les conducteurs disponibles
   - Filtrer par statut 'available'

2. **Calculer la distance** (PostGIS ou JavaScript)
   - Pour chaque conducteur, calculer la distance
   - Trier par distance

3. **Retourner les plus proches**
   - Limiter à 20 conducteurs maximum

### Exemple d'Implémentation

```javascript
async function findNearbyDrivers(latitude, longitude, radiusKm = 10) {
  // 1. Récupérer tous les conducteurs disponibles depuis Redis
  const availableDrivers = await redisService.getAvailableDrivers();
  
  // 2. Calculer la distance pour chaque conducteur
  const driversWithDistance = availableDrivers.map(driver => {
    const distance = calculateDistance(
      { latitude, longitude },
      { latitude: driver.latitude, longitude: driver.longitude }
    );
    return { ...driver, distance };
  });
  
  // 3. Filtrer par rayon et trier par distance
  const nearbyDrivers = driversWithDistance
    .filter(driver => driver.distance <= radiusKm)
    .sort((a, b) => a.distance - b.distance)
    .slice(0, 20);
  
  return nearbyDrivers;
}
```

---

## 🧹 Nettoyage des Données

### Nettoyage Automatique

**TTL:** Les données expirent automatiquement après 5 minutes d'inactivité.

**Nettoyage manuel:** Supprimer les conducteurs déconnectés.

```javascript
// Nettoyer les conducteurs expirés
await redisService.cleanupExpiredDrivers();
```

### Tâche Planifiée

**Fréquence:** Toutes les 5 minutes

**Action:** Nettoyer les conducteurs expirés et synchroniser avec la base de données.

---

## 📊 Statistiques Redis

### Métriques Disponibles

- Nombre total de conducteurs en ligne
- Nombre de conducteurs disponibles
- Nombre de conducteurs en course
- Nombre de conducteurs hors ligne

### Récupération

```javascript
const stats = await redisService.getStats();
// Retourne: { connected: true, drivers: 45, available: 30, inProgress: 15, offline: 0 }
```

---

## 🔐 Sécurité

### Réseau Privé (VPC)

Memorystore utilise un réseau privé (VPC) pour la sécurité. Seules les ressources dans le même VPC peuvent se connecter.

### Authentification

Memorystore n'utilise pas de mot de passe par défaut. L'authentification se fait via :
- Réseau VPC privé
- Autorisations IAM
- Service account

### Validation des Données

- Valider les coordonnées GPS (latitude: -90 à 90, longitude: -180 à 180)
- Valider le statut (doit être un statut valide)
- Valider le driverId (doit être un entier positif)

---

## 🚀 Intégration avec le Backend

### Initialisation

```javascript
// Dans server.postgres.js
const { getRedisService } = require('./services/RedisService');

// Initialiser Redis après la connexion à la base de données
const redisService = getRedisService();
await redisService.connect();
```

### Utilisation dans les Routes

```javascript
// Dans routes.postgres/driver.js
const { getRedisService } = require('../services/RedisService');

// Mettre à jour la position
router.post('/location/update', async (req, res) => {
  const redisService = getRedisService();
  await redisService.updateDriverLocation(req.user.id, req.body);
  res.json({ success: true });
});
```

---

## 📝 Exemples d'Utilisation

### Mettre à Jour la Position

```javascript
// Depuis l'application conducteur
const response = await fetch('/api/driver/location/update', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    latitude: -4.3276,
    longitude: 15.3136,
    status: 'available',
    heading: 90,
    speed: 45
  })
});
```

### Récupérer les Conducteurs Proches

```javascript
// Depuis l'application client
const response = await fetch('/api/location/drivers/nearby?lat=-4.3276&lon=15.3136&radius=5');
const drivers = await response.json();
```

---

## 🔍 Commandes Redis Utiles

### Via redis-cli

```bash
# Se connecter à Redis
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# Lister toutes les clés driver:*
KEYS driver:*

# Récupérer les informations d'un conducteur
HGETALL driver:4523

# Vérifier le TTL
TTL driver:4523

# Supprimer un conducteur
DEL driver:4523

# Statistiques
INFO stats
INFO memory
```

---

## 📈 Performances

### Optimisations

1. **Hash Redis** - Structure optimale pour les données structurées
2. **TTL automatique** - Nettoyage automatique des données expirées
3. **KEYS avec parcours** - Utiliser SCAN pour les grandes listes
4. **Pipeline** - Regrouper les commandes pour améliorer les performances

### Limites

- **Taille maximale** - 1 GB par défaut (développement)
- **Nombre de clés** - Limité par la mémoire
- **Fréquence de mise à jour** - Toutes les 2-3 secondes maximum

---

## 🚨 Dépannage

### Erreur: "Connection refused"

```bash
# Vérifier que l'instance est dans le même VPC
gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --format="value(authorizedNetwork)"
```

### Erreur: "Memory limit exceeded"

```bash
# Augmenter la taille de l'instance
gcloud redis instances update $REDIS_INSTANCE_NAME \
  --size=5 \
  --region=$REGION
```

### Erreur: "Key not found"

- Vérifier que le conducteur a mis à jour sa position récemment
- Vérifier le TTL de la clé
- Vérifier que le conducteur est bien connecté

---

## 📚 Documentation

- **Service Redis**: `backend/services/RedisService.js`
- **Guide de configuration**: `GCP_SETUP_ETAPE3.md`
- **Documentation Redis**: https://redis.io/documentation

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

