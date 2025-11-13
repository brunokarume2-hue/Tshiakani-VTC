# 🚀 Redéploiement Backend avec Redis - Tshiakani VTC

## ✅ Statut : Script de Déploiement Mis à Jour

Le script de déploiement a été mis à jour pour inclure les variables Redis et Twilio.

---

## 📋 Ce qui a été fait

### 1. Script de Déploiement Mis à Jour

- ✅ **Variables Redis ajoutées** : `REDIS_URL` (Upstash Redis) et `REDIS_HOST` (Redis local/Memorystore)
- ✅ **Support Upstash Redis** : Configuration pour Upstash Redis (gratuit, recommandé)
- ✅ **Variables Twilio ajoutées** : `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`, `TWILIO_CONTENT_SID`
- ✅ **Vérification des variables** : Le script vérifie que Redis est configuré (REDIS_URL ou REDIS_HOST)
- ✅ **Configuration dynamique** : Les variables Redis et Twilio sont ajoutées automatiquement si configurées

### 2. Guides de Redéploiement Créés

- ✅ **GUIDE_UPSTASH_REDIS.md** : Guide complet de configuration Upstash Redis (gratuit, recommandé)
- ✅ **GUIDE_REDEPLOIEMENT_REDIS.md** : Guide complet de redéploiement avec Redis Memorystore

---

## 🚀 Étapes pour Redéployer

### Étape 1 : Configurer les Variables dans le Script

Éditez le fichier `backend/scripts/deploy-cloud-run.sh` et configurez les variables :

#### Option 1 : Upstash Redis (Recommandé - GRATUIT)

```bash
# Variables Redis (Upstash Redis - GRATUIT)
REDIS_URL="redis://default:your_token@endpoint.upstash.io:6379"  # Récupérer depuis https://upstash.com/
REDIS_CONNECT_TIMEOUT="10000"
```

**Pour obtenir REDIS_URL** :
1. Créer un compte sur [https://upstash.com/](https://upstash.com/)
2. Créer une base de données Redis (tier gratuit)
3. Récupérer l'URL de connexion (REDIS_URL)

Consultez le guide complet : [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)

#### Option 2 : Redis Memorystore (Alternative - Payant)

```bash
# Variables Redis (Memorystore)
REDIS_HOST="10.x.x.x"  # Remplacez par l'adresse IP de votre instance Memorystore
REDIS_PORT="6379"
REDIS_PASSWORD=""  # Laissez vide si pas de mot de passe
REDIS_CONNECT_TIMEOUT="10000"
```

#### Variables Twilio

```bash
# Variables Twilio
TWILIO_ACCOUNT_SID="your_account_sid"  # Remplacez par votre Account SID
TWILIO_AUTH_TOKEN="your_auth_token"    # Remplacez par votre Auth Token
TWILIO_WHATSAPP_FROM="whatsapp:+14155238886"
TWILIO_PHONE_NUMBER=""  # Optionnel
TWILIO_CONTENT_SID="HX229f5a04fd0510ce1b071852155d3e75"
```

### Étape 2 : Créer une Instance Redis (si nécessaire)

#### Option 1 : Upstash Redis (Recommandé - GRATUIT)

Consultez le guide : [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)

#### Option 2 : Redis Memorystore (Alternative - Payant)

Si vous n'avez pas encore créé une instance Redis Memorystore dans GCP :

```bash
# Définir les variables
PROJECT_ID="tshiakani-vtc-99cea"
REGION="us-central1"
INSTANCE_NAME="tshiakani-redis"
TIER="basic"  # basic, standard, ou premium
SIZE="1"      # Taille en GB

# Créer l'instance Redis Memorystore
gcloud redis instances create ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --tier=${TIER} \
  --size=${SIZE} \
  --redis-version=redis_8_2

# Obtenir l'adresse IP interne
gcloud redis instances describe ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --format="value(host)"
```

### Étape 3 : Redéployer le Backend

```bash
cd backend
chmod +x scripts/deploy-cloud-run.sh
./scripts/deploy-cloud-run.sh
```

### Étape 4 : Vérifier le Déploiement

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-driver-backend \
  --region=us-central1 \
  --format="value(status.url)")

# Tester la route de santé
curl ${SERVICE_URL}/health

# Tester l'inscription avec OTP
curl -X POST ${SERVICE_URL}/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "name": "Test User",
    "role": "client"
  }'
```

---

## ⚠️ Important

### 1. Options Redis pour la Production

- **Recommandé** : **Upstash Redis (GRATUIT)** - 10 000 commandes/jour, suffisant pour < 3000 clients
- **Alternative** : **Redis Memorystore** - ~30 $/mois, pour une haute disponibilité
- **Développement local** : Utilisez Redis local (localhost:6379)

### 2. Variables Sensibles

- **Twilio** : Utilisez Secret Manager pour stocker `TWILIO_ACCOUNT_SID` et `TWILIO_AUTH_TOKEN` en production
- **Redis Password** : Utilisez Secret Manager pour stocker `REDIS_PASSWORD` si nécessaire

### 3. Configuration du VPC

- Cloud Run doit avoir accès au VPC où se trouve Redis Memorystore
- Redis Memorystore et Cloud Run doivent être dans la même région

---

## 🔍 Vérification

### Vérifier les Logs

```bash
# Voir les logs du service Cloud Run
gcloud run services logs read tshiakani-driver-backend \
  --region=us-central1 \
  --limit=50

# Chercher les messages Redis
gcloud run services logs read tshiakani-driver-backend \
  --region=us-central1 \
  --limit=50 | grep -i redis
```

### Vérifier la Connexion Redis

Dans les logs, vous devriez voir :
```
✅ Redis connecté avec succès
Redis client ready
```

### Tester l'Authentification OTP

```bash
# 1. Demander un code OTP
curl -X POST ${SERVICE_URL}/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "name": "Test User",
    "role": "client"
  }'

# Réponse attendue:
# {
#   "success": true,
#   "message": "Code de vérification envoyé par SMS/WhatsApp",
#   "phoneNumber": "+243900000000",
#   "remainingAttempts": 2
# }
```

---

## 📝 Checklist de Redéploiement

- [ ] (Option 1) Compte Upstash créé et base de données Redis créée
- [ ] (Option 1) REDIS_URL récupérée et configurée dans le script
- [ ] (Option 2) Instance Redis Memorystore créée dans GCP (si nécessaire)
- [ ] (Option 2) Adresse IP Redis obtenue et configurée dans le script
- [ ] Variables Redis configurées dans le script de déploiement
- [ ] Variables Twilio configurées dans le script de déploiement
- [ ] Script de déploiement exécuté
- [ ] Logs vérifiés pour confirmer la connexion Redis
- [ ] Test d'inscription avec OTP réussi
- [ ] Test de connexion avec OTP réussi

---

## 🎉 Résumé

Une fois le redéploiement terminé :

1. ✅ Upstash Redis configuré (gratuit, recommandé) ou Redis Memorystore (payant)
2. ✅ Variables Redis configurées dans Cloud Run
3. ✅ Variables Twilio configurées dans Cloud Run
4. ✅ Backend redéployé avec les nouvelles variables
5. ✅ Système d'authentification OTP fonctionnel en production

**Le système d'authentification OTP est maintenant prêt pour la production !**

**Économies** : 30 $/mois (Redis Memorystore) → 0 $/mois (Upstash Redis)

---

## 📚 Documentation

- **GUIDE_UPSTASH_REDIS.md** : Guide complet de configuration Upstash Redis (gratuit, recommandé)
- **GUIDE_REDEPLOIEMENT_REDIS.md** : Guide complet de redéploiement avec Redis Memorystore
- **REDIS_INSTALLE_ET_CONFIGURE.md** : Documentation de l'installation Redis locale
- **GUIDE_CONFIGURATION_REDIS.md** : Guide de configuration Redis complet

---

**Date** : 2025-11-12  
**Statut** : ✅ **SCRIPT DE DÉPLOIEMENT MIS À JOUR**

