# 🔴 Étape 3 : Configuration Memorystore (Redis) - Temps Réel

## 🎯 Objectif

Configurer Memorystore (Redis) pour le suivi en temps réel des conducteurs avec mise à jour de position toutes les 2-3 secondes.

---

## 📋 Prérequis

1. ✅ Étape 1 complétée (Projet GCP créé, APIs activées)
2. ✅ Étape 2 complétée (Cloud SQL configuré)
3. ✅ Memorystore API activée
4. ✅ gcloud CLI installé et configuré

---

## 🚀 Étapes de Configuration

### 1. Créer une Instance Memorystore (Redis)

#### Configuration Recommandée

- **Version Redis**: Redis 6.x ou 7.x
- **Tier**: `BASIC` (développement) ou `STANDARD_HA` (production)
- **Memory size**: 1 GB minimum (développement) ou 5 GB+ (production)
- **Region**: Même région que Cloud SQL et Cloud Run
- **Network**: VPC (réseau privé)

#### Créer l'Instance via Script

```bash
# Exécuter le script de création
./scripts/gcp-create-redis.sh
```

#### Créer l'Instance Manuellement

```bash
# Définir les variables
export PROJECT_ID="tshiakani-vtc"
export REDIS_INSTANCE_NAME="tshiakani-vtc-redis"
export REGION="us-central1"
export MEMORY_SIZE_GB=1  # 1 GB pour dev, 5+ GB pour prod
export TIER="BASIC"  # BASIC pour dev, STANDARD_HA pour prod

# Créer l'instance Redis
gcloud redis instances create $REDIS_INSTANCE_NAME \
  --size=$MEMORY_SIZE_GB \
  --region=$REGION \
  --tier=$TIER \
  --redis-version=REDIS_7_0 \
  --project=$PROJECT_ID
```

---

### 2. Obtenir les Informations de Connexion

```bash
# Obtenir l'IP et le port de l'instance Redis
gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(host,port)"

# Obtenir l'IP uniquement
REDIS_HOST=$(gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(host)")

# Le port par défaut est 6379
REDIS_PORT=6379
```

---

### 3. Configurer les Autorisations

#### Autoriser Cloud Run à Se Connecter

```bash
# Accorder l'accès au compte de service
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/redis.editor"
```

---

### 4. Structure de Données Redis

#### Clé: `driver:<driver_id>`

**Format**: Hash Redis

**Champs:**
- `lat` (String) - Latitude actuelle
- `lon` (String) - Longitude actuelle
- `status` (String) - Statut: 'available', 'en_route_to_pickup', 'in_progress', 'offline'
- `last_update` (String) - Dernier horodatage (ISO 8601)
- `current_ride_id` (String) - ID de la course actuelle (si en course)
- `heading` (String) - Direction en degrés (optionnel)
- `speed` (String) - Vitesse en km/h (optionnel)

#### Exemple de Données

```redis
HSET driver:4523 lat "-4.3276" lon "15.3136" status "available" last_update "2025-01-15T10:30:00Z" current_ride_id "" heading "0" speed "0"
```

#### Opérations Redis

**Mettre à jour la position:**
```redis
HSET driver:4523 lat "-4.3276" lon "15.3136" last_update "2025-01-15T10:30:00Z"
```

**Mettre à jour le statut:**
```redis
HSET driver:4523 status "in_progress" current_ride_id "123"
```

**Récupérer les informations:**
```redis
HGETALL driver:4523
```

**Supprimer (quand le conducteur se déconnecte):**
```redis
DEL driver:4523
```

---

### 5. Mise à Jour de Position (Toutes les 2-3 secondes)

L'application conducteur doit mettre à jour la position toutes les 2-3 secondes.

**Format de la requête:**
```json
{
  "driverId": 4523,
  "latitude": -4.3276,
  "longitude": 15.3136,
  "status": "available",
  "heading": 90,
  "speed": 45
}
```

**Endpoint backend:**
```
POST /api/driver/location/update
```

**Action Redis:**
```redis
HSET driver:4523 lat "-4.3276" lon "15.3136" status "available" last_update "2025-01-15T10:30:00Z" heading "90" speed "45"
```

---

### 6. Recherche de Conducteurs Proches

Utiliser Redis pour une recherche rapide, puis PostGIS pour la précision.

**Stratégie:**
1. Récupérer tous les conducteurs disponibles depuis Redis
2. Filtrer par statut 'available'
3. Calculer la distance pour chaque conducteur
4. Trier par distance
5. Retourner les plus proches

---

### 7. Expiration des Données

Les données Redis doivent expirer après un certain temps d'inactivité.

**TTL (Time To Live):**
- 5 minutes pour les conducteurs en ligne
- 30 secondes pour les conducteurs hors ligne (nettoyage automatique)

**Configuration:**
```redis
EXPIRE driver:4523 300  # 5 minutes
```

---

## 🔍 Vérification

### Vérifier l'Instance

```bash
# Vérifier l'état de l'instance
gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID

# Vérifier les métriques
gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(state,memorySizeGb,redisVersion)"
```

### Tester la Connexion

```bash
# Installer redis-cli si nécessaire
brew install redis

# Se connecter à Redis (depuis une machine autorisée)
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# Tester les commandes
PING
HSET driver:4523 lat "-4.3276" lon "15.3136" status "available" last_update "2025-01-15T10:30:00Z"
HGETALL driver:4523
```

---

## 📝 Variables d'Environnement

Mettre à jour `.env.gcp` :

```bash
# Memorystore (Redis) Configuration
export REDIS_INSTANCE_NAME="tshiakani-vtc-redis"
export REDIS_HOST="CHANGE_ME"  # IP de l'instance Redis
export REDIS_PORT="6379"
export REDIS_PASSWORD=""  # Vide pour Memorystore (authentification via VPC)
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

---

## 🚨 Dépannage

### Erreur: "Instance creation failed"

```bash
# Vérifier les quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Vérifier les limites Redis
gcloud redis instances list --project=$PROJECT_ID
```

### Erreur: "Connection refused"

```bash
# Vérifier que l'instance est dans le même VPC
gcloud redis instances describe $REDIS_INSTANCE_NAME \
  --region=$REGION \
  --format="value(authorizedNetwork)"

# Vérifier que Cloud Run est dans le même VPC
```

### Erreur: "Memory limit exceeded"

```bash
# Augmenter la taille de l'instance
gcloud redis instances update $REDIS_INSTANCE_NAME \
  --size=5 \
  --region=$REGION \
  --project=$PROJECT_ID
```

---

## 📚 Ressources Utiles

- **Documentation Memorystore**: https://cloud.google.com/memorystore/docs/redis
- **Documentation Redis**: https://redis.io/documentation
- **Guide de connexion**: https://cloud.google.com/memorystore/docs/redis/connect-redis-instance

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée :

1. **Étape 4**: Déploiement du Backend sur Cloud Run
2. **Étape 5**: Configuration du Dashboard Admin
3. **Intégration**: Connecter le backend à Redis pour le suivi temps réel

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

