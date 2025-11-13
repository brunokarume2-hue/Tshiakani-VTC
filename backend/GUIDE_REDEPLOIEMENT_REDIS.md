# 🚀 Guide de Redéploiement avec Redis - Tshiakani VTC

## 📋 Prérequis

Avant de redéployer le backend avec Redis, vous devez :

1. ✅ **Redis installé et configuré en local** (déjà fait)
2. ⏳ **Choisir une option Redis pour la production** :
   - **Option 1 (Recommandé)** : **Upstash Redis (GRATUIT)** - 10 000 commandes/jour, suffisant pour < 3000 clients
   - **Option 2 (Alternative)** : **Redis Memorystore (Payant)** - ~30 $/mois, pour une haute disponibilité
3. ⏳ **Configurer les variables d'environnement Redis dans GCP**
4. ⏳ **Configurer les variables d'environnement Twilio dans GCP**
5. ⏳ **Redéployer le backend avec les nouvelles variables**

**Recommandation** : Utilisez **Upstash Redis** (gratuit) pour réduire les coûts. Consultez [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md) pour la configuration.

---

## 🚀 Étape 1 : Choisir une Option Redis pour la Production

### Option 1 : Upstash Redis (Recommandé - GRATUIT)

**Avantages** :
- **Gratuit** : 0 $/mois (tier gratuit, 10k commandes/jour)
- **Suffisant** : 10 000 commandes/jour suffisent pour < 3000 clients
- **Hébergé** : Pas besoin d'installer/maintenir Redis
- **Compatible** : Compatible avec Redis (pas de changement de code)

**Configuration** :
1. Créer un compte sur [https://upstash.com/](https://upstash.com/)
2. Créer une base de données Redis (tier gratuit)
3. Récupérer l'URL de connexion (REDIS_URL)
4. Configurer `REDIS_URL` dans `deploy-cloud-run.sh`

**Guide complet** : [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)

### Option 2 : Redis Memorystore (Alternative - Payant)

**Avantages** :
- **Haute disponibilité** : 99,9% de disponibilité
- **Hébergé** : Hébergé par Google Cloud
- **Scalable** : Peut être mis à l'échelle si nécessaire

**Inconvénients** :
- **Payant** : ~30 $/mois (tier basic, 1 GB)
- **Nécessite la facturation** : Facturation GCP requise

---

## 🔧 Étape 2 : Créer une Instance Redis (si Option 2)

### 1.1 Créer l'Instance Redis Memorystore

```bash
# Définir les variables
PROJECT_ID="tshiakani-vtc-99cea"
REGION="us-central1"
INSTANCE_NAME="tshiakani-redis"
TIER="basic"  # basic, standard, ou premium
SIZE="1"      # Taille en GB (1 pour développement, 5+ pour production)

# Créer l'instance Redis Memorystore
gcloud redis instances create ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --tier=${TIER} \
  --size=${SIZE} \
  --redis-version=redis_8_2
```

### 1.2 Obtenir l'Adresse IP de l'Instance

```bash
# Obtenir l'adresse IP interne
gcloud redis instances describe ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --format="value(host)"

# Réponse attendue: 10.x.x.x (adresse IP interne)
```

### 1.3 Configurer la Connexion

```bash
# Obtenir les informations complètes de l'instance
gcloud redis instances describe ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --format="yaml"
```

**Important** :
- L'adresse IP interne (ex: `10.x.x.x`) sera utilisée dans `REDIS_HOST`
- Le port par défaut est `6379`
- Si l'instance a un mot de passe, vous devrez le configurer via Secret Manager

---

## 🔐 Étape 3 : Configurer les Variables d'Environnement dans GCP

### 2.1 Variables Redis

#### Option 1 : Variables d'Environnement Directes (Développement)

```bash
# Dans le script de déploiement (deploy-cloud-run.sh)
REDIS_HOST="10.x.x.x"  # Adresse IP de Memorystore
REDIS_PORT="6379"
REDIS_PASSWORD=""  # Laissez vide si pas de mot de passe
REDIS_CONNECT_TIMEOUT="10000"
```

#### Option 2 : Secret Manager (Recommandé pour Production)

```bash
# Créer un secret pour le mot de passe Redis (si nécessaire)
gcloud secrets create redis-password \
  --project=${PROJECT_ID} \
  --data-file=- <<< "votre_mot_de_passe_redis"

# Donner accès au secret au service Cloud Run
gcloud secrets add-iam-policy-binding redis-password \
  --project=${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

### 2.2 Variables Twilio

#### Option 1 : Variables d'Environnement Directes (Développement)

```bash
# Dans le script de déploiement (deploy-cloud-run.sh)
TWILIO_ACCOUNT_SID="your_account_sid"
TWILIO_AUTH_TOKEN="your_auth_token"
TWILIO_WHATSAPP_FROM="whatsapp:+14155238886"
TWILIO_PHONE_NUMBER="+1234567890"  # Optionnel
TWILIO_CONTENT_SID="HX229f5a04fd0510ce1b071852155d3e75"
```

#### Option 2 : Secret Manager (Recommandé pour Production)

```bash
# Créer des secrets pour Twilio
gcloud secrets create twilio-account-sid \
  --project=${PROJECT_ID} \
  --data-file=- <<< "your_account_sid"

gcloud secrets create twilio-auth-token \
  --project=${PROJECT_ID} \
  --data-file=- <<< "your_auth_token"

gcloud secrets create twilio-content-sid \
  --project=${PROJECT_ID} \
  --data-file=- <<< "HX229f5a04fd0510ce1b071852155d3e75"

# Donner accès aux secrets au service Cloud Run
SERVICE_ACCOUNT="tshiakani-driver-backend@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud secrets add-iam-policy-binding twilio-account-sid \
  --project=${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding twilio-auth-token \
  --project=${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding twilio-content-sid \
  --project=${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 🚀 Étape 3 : Redéployer le Backend

### 3.1 Mettre à Jour le Script de Déploiement

Le script `deploy-cloud-run.sh` a été mis à jour pour inclure les variables Redis et Twilio.

### 3.2 Configurer les Variables dans le Script

Éditez le fichier `backend/scripts/deploy-cloud-run.sh` et configurez les variables :

```bash
# Variables Redis (Memorystore)
REDIS_HOST="10.x.x.x"  # Remplacez par l'adresse IP de votre instance Memorystore
REDIS_PORT="6379"
REDIS_PASSWORD=""  # Laissez vide si pas de mot de passe
REDIS_CONNECT_TIMEOUT="10000"

# Variables Twilio
TWILIO_ACCOUNT_SID="your_account_sid"  # Remplacez par votre Account SID
TWILIO_AUTH_TOKEN="your_auth_token"    # Remplacez par votre Auth Token
TWILIO_WHATSAPP_FROM="whatsapp:+14155238886"
TWILIO_PHONE_NUMBER=""  # Optionnel
TWILIO_CONTENT_SID="HX229f5a04fd0510ce1b071852155d3e75"
```

### 3.3 Déployer

```bash
cd backend
chmod +x scripts/deploy-cloud-run.sh
./scripts/deploy-cloud-run.sh
```

### 3.4 Vérifier le Déploiement

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

## 🔍 Étape 4 : Vérifier la Connexion Redis

### 4.1 Vérifier les Logs

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

### 4.2 Vérifier la Connexion Redis

Dans les logs, vous devriez voir :
```
✅ Redis connecté avec succès
Redis client ready
```

### 4.3 Tester l'Authentification OTP

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

## ⚠️ Dépannage

### Erreur: "Connection refused" ou "Redis is not connected"

**Problème** : Redis Memorystore n'est pas accessible depuis Cloud Run.

**Solution** :
1. Vérifier que l'instance Redis Memorystore est dans la même région que Cloud Run
2. Vérifier que l'adresse IP Redis est correcte (`REDIS_HOST`)
3. Vérifier que Cloud Run a accès au VPC où se trouve Redis Memorystore
4. Vérifier les règles de pare-feu (firewall rules)

### Erreur: "Authentication failed" ou "Invalid password"

**Problème** : Le mot de passe Redis est incorrect.

**Solution** :
1. Vérifier que `REDIS_PASSWORD` est correct dans les variables d'environnement
2. Vérifier que le secret dans Secret Manager est correct
3. Vérifier que le service Cloud Run a accès au secret

### Erreur: "Twilio authentication failed"

**Problème** : Les variables Twilio sont incorrectes.

**Solution** :
1. Vérifier que `TWILIO_ACCOUNT_SID` est correct
2. Vérifier que `TWILIO_AUTH_TOKEN` est correct
3. Vérifier que `TWILIO_CONTENT_SID` est correct
4. Vérifier que les secrets dans Secret Manager sont corrects

### Erreur: "Service temporarily unavailable"

**Problème** : Redis n'est pas disponible, mais le serveur continue de fonctionner.

**Solution** :
1. Vérifier que Redis Memorystore est en cours d'exécution
2. Vérifier la connexion réseau entre Cloud Run et Redis Memorystore
3. Vérifier les logs pour plus d'informations

---

## ✅ Checklist de Redéploiement

- [ ] Instance Redis Memorystore créée dans GCP
- [ ] Adresse IP Redis obtenue et configurée
- [ ] Variables Redis configurées dans le script de déploiement
- [ ] Variables Twilio configurées dans le script de déploiement
- [ ] Secrets créés dans Secret Manager (optionnel)
- [ ] Permissions configurées pour Secret Manager (optionnel)
- [ ] Script de déploiement mis à jour
- [ ] Backend redéployé sur Cloud Run
- [ ] Logs vérifiés pour confirmer la connexion Redis
- [ ] Test d'inscription avec OTP réussi
- [ ] Test de connexion avec OTP réussi

---

## 📝 Notes Importantes

1. **Redis Memorystore** : Pour la production, utilisez Redis Memorystore dans GCP au lieu de localhost
2. **Secret Manager** : Utilisez Secret Manager pour stocker les valeurs sensibles (mots de passe, tokens)
3. **Région** : Assurez-vous que Redis Memorystore et Cloud Run sont dans la même région pour réduire la latence
4. **VPC** : Cloud Run doit avoir accès au VPC où se trouve Redis Memorystore
5. **Sécurité** : Ne stockez jamais les mots de passe ou tokens dans le code source

---

## 🎉 Résumé

Une fois le redéploiement terminé :

1. ✅ Redis Memorystore est configuré dans GCP
2. ✅ Variables Redis configurées dans Cloud Run
3. ✅ Variables Twilio configurées dans Cloud Run
4. ✅ Backend redéployé avec les nouvelles variables
5. ✅ Système d'authentification OTP fonctionnel en production

**Le système d'authentification OTP est maintenant prêt pour la production !**

---

**Date** : 2025-11-12  
**Statut** : ✅ **GUIDE DE REDÉPLOIEMENT CRÉÉ**

