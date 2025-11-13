# ⏱️ Timeline d'Exécution - Déploiement Backend VTC sur GCP

## 📊 Vue d'Ensemble Visuelle

```
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 0 : Vérification des Prérequis (5-10 min)               │
│  ✓ gcloud installé                                              │
│  ✓ Docker installé                                              │
│  ✓ APIs activées                                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 1 : Cloud SQL (10-15 min)                                │
│  1.1 Créer l'instance Cloud SQL (5-10 min)                     │
│  1.2 Initialiser la base de données (2-3 min)                  │
│  1.3 Tester les inscriptions (1-2 min)                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 2 : Memorystore Redis (15-25 min)                        │
│  2.1 Créer l'instance Memorystore (10-15 min)                  │
│  2.2 Configurer le VPC Connector (5-10 min)                    │
│  2.3 Tester la connexion Redis (après Étape 3)                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 3 : Cloud Run (20-30 min)                                │
│  3.1 Build l'image Docker (5-10 min)                           │
│  3.2 Configurer Artifact Registry (2-3 min)                    │
│  3.3 Push l'image Docker (5-10 min)                            │
│  3.4 Déployer sur Cloud Run (5-10 min)                         │
│  3.5 Configurer les variables d'environnement (2-3 min)        │
│  3.6 Configurer les permissions IAM (2-3 min)                  │
│  3.7 Tester les endpoints API (2-3 min)                        │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 4 : Google Maps & FCM (20-30 min)                        │
│  4.1 Activer les APIs Google Maps (1-2 min)                    │
│  4.2 Créer et configurer la clé API (5-10 min)                 │
│  4.3 Tester le calcul d'itinéraire (2-3 min)                   │
│  4.4 Configurer Firebase Cloud Messaging (10-15 min)           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 5 : Monitoring (15-25 min)                               │
│  5.1 Configurer Cloud Logging (2-3 min)                        │
│  5.2 Configurer Cloud Monitoring (1-2 min)                     │
│  5.3 Créer les alertes (5-10 min)                              │
│  5.4 Configurer les notifications (5-10 min)                   │
│  5.5 Créer les tableaux de bord (5-10 min)                     │
│  5.6 Tester les alertes (2-3 min)                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
                    ✅ DÉPLOIEMENT TERMINÉ
```

---

## 🎯 Ordre d'Exécution Détaillé

### Étape 0 : Prérequis (5-10 minutes)

```bash
# Vérifier gcloud
gcloud --version
gcloud config get-value project

# Vérifier Docker
docker --version

# Activer les APIs
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

**⏱️ Temps** : 5-10 minutes  
**📋 Vérifications** : gcloud installé, Docker installé, APIs activées

---

### Étape 1 : Cloud SQL (10-15 minutes)

```bash
# 1.1 Créer l'instance (5-10 min)
./scripts/gcp-create-cloud-sql.sh

# 1.2 Initialiser la base de données (2-3 min)
./scripts/gcp-init-database.sh

# 1.3 Tester les inscriptions (1-2 min)
curl -X POST http://localhost:3000/api/auth/signup \
  -d '{"phoneNumber": "+243900000001", "name": "Test", "role": "client"}'
```

**⏱️ Temps** : 10-15 minutes  
**📋 Vérifications** : Instance créée, Tables créées, Inscriptions fonctionnelles

---

### Étape 2 : Memorystore Redis (15-25 minutes)

```bash
# 2.1 Créer l'instance (10-15 min)
./scripts/gcp-create-redis.sh

# 2.2 Configurer le VPC Connector (5-10 min)
gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28

# 2.3 Tester la connexion (après Étape 3)
curl $SERVICE_URL/health
```

**⏱️ Temps** : 15-25 minutes  
**📋 Vérifications** : Instance créée, VPC Connector configuré, Connexion fonctionnelle

---

### Étape 3 : Cloud Run (20-30 minutes)

```bash
# 3.1 Build l'image Docker (5-10 min)
cd backend
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .

# 3.2 Configurer Artifact Registry (2-3 min)
gcloud artifacts repositories create tshiakani-vtc-repo \
  --repository-format=docker \
  --location=us-central1

# 3.3 Push l'image (5-10 min)
docker tag gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest
docker push us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest

# 3.4 Déployer sur Cloud Run (5-10 min)
cd ..
./scripts/gcp-deploy-backend.sh

# 3.5 Configurer les variables d'environnement (2-3 min)
./scripts/gcp-set-cloud-run-env.sh

# 3.6 Configurer les permissions IAM (2-3 min)
# (Voir GCP_ORDRE_EXECUTION.md pour les détails)

# 3.7 Tester les endpoints API (2-3 min)
curl $SERVICE_URL/health
```

**⏱️ Temps** : 20-30 minutes  
**📋 Vérifications** : Image buildée, Service déployé, Variables configurées, API fonctionnelle

---

### Étape 4 : Google Maps & FCM (20-30 minutes)

```bash
# 4.1 Activer les APIs (1-2 min)
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# 4.2 Créer et configurer la clé API (5-10 min)
# (Via console GCP ou Secret Manager)

# 4.3 Tester le calcul d'itinéraire (2-3 min)
curl -X POST $SERVICE_URL/api/ride/request \
  -d '{"pickupLocation": {"latitude": -4.3276, "longitude": 15.3363}, ...}'

# 4.4 Configurer Firebase Cloud Messaging (10-15 min)
# (Via console Firebase)
```

**⏱️ Temps** : 20-30 minutes  
**📋 Vérifications** : APIs activées, Clé API configurée, Itinéraire calculé, FCM configuré

---

### Étape 5 : Monitoring (15-25 minutes)

```bash
# 5.1 Configurer Cloud Logging (2-3 min)
./scripts/gcp-setup-monitoring.sh

# 5.2 Configurer Cloud Monitoring (1-2 min)
gcloud monitoring time-series list --limit=10

# 5.3 Créer les alertes (5-10 min)
./scripts/gcp-create-alerts.sh

# 5.4 Configurer les notifications (5-10 min)
# (Via console GCP ou scripts)

# 5.5 Créer les tableaux de bord (5-10 min)
./scripts/gcp-create-dashboard.sh

# 5.6 Tester les alertes (2-3 min)
curl -X POST $SERVICE_URL/api/payment/process \
  -d '{"rideId": "invalid", "amount": 1000, "paymentToken": "invalid"}'
```

**⏱️ Temps** : 15-25 minutes  
**📋 Vérifications** : Logging configuré, Monitoring configuré, Alertes créées, Tableaux de bord créés

---

## 📊 Résumé Temporel

| Étape | Actions | Temps Minimum | Temps Maximum | Temps Moyen |
|-------|---------|---------------|---------------|-------------|
| **0. Prérequis** | Vérification, Activation APIs | 5 min | 10 min | 7 min |
| **1. Cloud SQL** | Création instance, Initialisation BDD | 10 min | 15 min | 12 min |
| **2. Redis** | Création instance, VPC Connector | 15 min | 25 min | 20 min |
| **3. Cloud Run** | Build, Push, Déploiement, Configuration | 20 min | 30 min | 25 min |
| **4. Google Maps** | APIs, Clé API, FCM | 20 min | 30 min | 25 min |
| **5. Monitoring** | Logging, Monitoring, Alertes, Dashboards | 15 min | 25 min | 20 min |
| **TOTAL** | | **85 min** | **135 min** | **110 min** |

**⏱️ Temps total estimé** : 1h30 - 2h15 (85-135 minutes)

---

## 🎯 Points d'Attention

### ⚠️ Temps d'Attente

- **Cloud SQL** : La création de l'instance peut prendre **5-10 minutes**
- **Memorystore** : La création de l'instance peut prendre **10-15 minutes**
- **Cloud Run** : Le déploiement peut prendre **5-10 minutes**

### ⚠️ Dépendances

- **Étape 2.3** (Test Redis) doit être effectuée **après Étape 3** (Cloud Run déployé)
- **Étape 4.3** (Test itinéraire) nécessite que **Étape 3** soit terminée
- **Étape 5.6** (Test alertes) nécessite que **Étape 3** et **Étape 5** soient terminées

### ⚠️ Actions Parallèles Possibles

- **Étape 1** et **Étape 2** peuvent être effectuées en parallèle (création des instances)
- **Étape 4.1** (Activation APIs) peut être effectuée pendant **Étape 3** (Build Docker)

---

## ✅ Checklist Rapide

### Étape 0 : Prérequis
- [ ] gcloud installé
- [ ] Docker installé
- [ ] APIs activées

### Étape 1 : Cloud SQL
- [ ] Instance créée
- [ ] BDD initialisée
- [ ] Tables créées

### Étape 2 : Redis
- [ ] Instance créée
- [ ] VPC Connector configuré

### Étape 3 : Cloud Run
- [ ] Image buildée
- [ ] Service déployé
- [ ] Variables configurées
- [ ] API fonctionnelle

### Étape 4 : Google Maps
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] FCM configuré

### Étape 5 : Monitoring
- [ ] Logging configuré
- [ ] Monitoring configuré
- [ ] Alertes créées
- [ ] Dashboards créés

---

## 📚 Documentation

### Guides Complets
- `GCP_ORDRE_EXECUTION.md` - Guide détaillé de l'ordre d'exécution
- `GCP_PROCHAINES_ACTIONS.md` - Guide des actions à effectuer
- `GCP_CHECKLIST_RAPIDE.md` - Checklist rapide

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore
- `GCP_SETUP_ETAPE4.md` - Cloud Run
- `GCP_SETUP_ETAPE5.md` - Monitoring

---

## 🚀 Commencer Maintenant

1. **Lire** `GCP_ORDRE_EXECUTION.md` pour les détails complets
2. **Suivre** la timeline ci-dessus étape par étape
3. **Vérifier** chaque étape avant de passer à la suivante
4. **Tester** chaque fonctionnalité après configuration

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Timeline d'exécution pour le déploiement

