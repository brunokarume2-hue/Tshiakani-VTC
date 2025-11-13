# 🔧 Dépannage Rapide - Déploiement Backend VTC sur GCP

## 🚨 Problèmes Courants et Solutions Rapides

### 1. ❌ Erreur : Instance Cloud SQL non accessible

#### 🔍 Diagnostic
```bash
# Vérifier le statut de l'instance
gcloud sql instances describe tshiakani-vtc-db \
  --format="value(state)"

# Vérifier les permissions
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc-backend@tshiakani-vtc.iam.gserviceaccount.com"
```

#### ✅ Solutions
1. **Instance non créée** : Exécuter `./scripts/gcp-create-cloud-sql.sh`
2. **Instance en cours de création** : Attendre 5-10 minutes
3. **Permissions manquantes** : Ajouter `roles/cloudsql.client`
4. **INSTANCE_CONNECTION_NAME incorrect** : Vérifier le format `project:region:instance`

---

### 2. ❌ Erreur : Instance Memorystore non accessible

#### 🔍 Diagnostic
```bash
# Vérifier le statut de l'instance
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --format="value(state)"

# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list --region=us-central1
```

#### ✅ Solutions
1. **Instance non créée** : Exécuter `./scripts/gcp-create-redis.sh`
2. **Instance en cours de création** : Attendre 10-15 minutes
3. **VPC Connector manquant** : Créer le VPC Connector
4. **Cloud Run non configuré pour VPC** : Configurer `vpcAccess` dans Cloud Run

---

### 3. ❌ Erreur : Déploiement Cloud Run échoué

#### 🔍 Diagnostic
```bash
# Vérifier les logs de build
gcloud builds list --limit=5

# Vérifier les images
gcloud artifacts docker images list us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo

# Vérifier le service
gcloud run services describe tshiakani-vtc-backend --region=us-central1
```

#### ✅ Solutions
1. **Image non buildée** : Exécuter `docker build -t ...`
2. **Image non poussée** : Exécuter `docker push ...`
3. **Artifact Registry non configuré** : Créer le dépôt Artifact Registry
4. **Permissions manquantes** : Vérifier les permissions IAM

---

### 4. ❌ Erreur : Connexion Redis échouée

#### 🔍 Diagnostic
```bash
# Vérifier la connexion Redis
curl https://tshiakani-vtc-backend-xxxxx.run.app/health

# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors describe tshiakani-vtc-connector \
  --region=us-central1

# Vérifier la configuration Cloud Run
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.vpcAccess)"
```

#### ✅ Solutions
1. **VPC Connector non créé** : Créer le VPC Connector
2. **Cloud Run non configuré** : Configurer `vpcAccess` dans Cloud Run
3. **Variables d'environnement incorrectes** : Vérifier `REDIS_HOST` et `REDIS_PORT`
4. **Règles de firewall** : Vérifier les règles de firewall

---

### 5. ❌ Erreur : Calcul d'itinéraire Google Maps échoué

#### 🔍 Diagnostic
```bash
# Vérifier la clé API
gcloud secrets versions access latest --secret=google-maps-api-key

# Vérifier les APIs activées
gcloud services list --enabled \
  --filter="name:routes OR name:places OR name:geocoding"

# Vérifier les quotas
gcloud services list --enabled --filter="name:routes"
```

#### ✅ Solutions
1. **Clé API manquante** : Créer et configurer la clé API
2. **APIs non activées** : Activer les APIs Google Maps
3. **Quotas dépassés** : Vérifier et augmenter les quotas
4. **Restrictions d'API** : Vérifier les restrictions d'API

---

### 6. ❌ Erreur : Variables d'environnement manquantes

#### 🔍 Diagnostic
```bash
# Vérifier les variables d'environnement
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

#### ✅ Solutions
1. **Variables non configurées** : Exécuter `./scripts/gcp-set-cloud-run-env.sh`
2. **Secrets non accessibles** : Vérifier les permissions Secret Manager
3. **Format incorrect** : Vérifier le format des variables
4. **Variables manquantes** : Ajouter les variables manquantes

---

### 7. ❌ Erreur : Permissions IAM manquantes

#### 🔍 Diagnostic
```bash
# Vérifier les permissions
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}"
```

#### ✅ Solutions
1. **Permissions Cloud SQL** : Ajouter `roles/cloudsql.client`
2. **Permissions Logging** : Ajouter `roles/logging.logWriter`
3. **Permissions Monitoring** : Ajouter `roles/monitoring.metricWriter`
4. **Permissions Secret Manager** : Ajouter `roles/secretmanager.secretAccessor`

---

### 8. ❌ Erreur : Alertes non déclenchées

#### 🔍 Diagnostic
```bash
# Vérifier les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc \
  --limit=10

# Vérifier les alertes
gcloud alpha monitoring policies list --project=tshiakani-vtc

# Vérifier les notifications
gcloud alpha monitoring channels list --project=tshiakani-vtc
```

#### ✅ Solutions
1. **Métriques non enregistrées** : Vérifier que Cloud Monitoring est configuré
2. **Alertes non créées** : Exécuter `./scripts/gcp-create-alerts.sh`
3. **Notifications non configurées** : Configurer les canaux de notification
4. **Seuils incorrects** : Vérifier les seuils des alertes

---

## 🔍 Commandes de Diagnostic Rapide

### Vérifier l'État des Services

```bash
# Vérifier Cloud SQL
gcloud sql instances list

# Vérifier Memorystore
gcloud redis instances list --region=us-central1

# Vérifier Cloud Run
gcloud run services list --region=us-central1

# Vérifier Artifact Registry
gcloud artifacts repositories list
```

### Vérifier les Logs

```bash
# Logs Cloud Run
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=10

# Logs Cloud SQL
gcloud sql operations list --instance=tshiakani-vtc-db

# Logs de build
gcloud builds list --limit=5
```

### Vérifier les Métriques

```bash
# Métriques de latence
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc \
  --limit=10

# Métriques d'erreurs
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/errors"' \
  --project=tshiakani-vtc \
  --limit=10
```

---

## ✅ Checklist de Dépannage

### Problème de Connexion
- [ ] Vérifier le statut de l'instance
- [ ] Vérifier les permissions IAM
- [ ] Vérifier les variables d'environnement
- [ ] Vérifier les règles de firewall
- [ ] Vérifier le VPC Connector

### Problème de Déploiement
- [ ] Vérifier les logs de build
- [ ] Vérifier les images Docker
- [ ] Vérifier Artifact Registry
- [ ] Vérifier les permissions IAM
- [ ] Vérifier les variables d'environnement

### Problème de Performance
- [ ] Vérifier la latence des APIs
- [ ] Vérifier l'utilisation des ressources
- [ ] Vérifier les requêtes de base de données
- [ ] Vérifier l'utilisation du cache
- [ ] Vérifier la mise à l'échelle

### Problème de Monitoring
- [ ] Vérifier Cloud Logging
- [ ] Vérifier Cloud Monitoring
- [ ] Vérifier les métriques
- [ ] Vérifier les alertes
- [ ] Vérifier les notifications

---

## 🚨 Solutions d'Urgence

### Service Complètement Hors Ligne

```bash
# 1. Vérifier le statut du service
gcloud run services describe tshiakani-vtc-backend --region=us-central1

# 2. Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=50

# 3. Redémarrer le service
gcloud run services update tshiakani-vtc-backend --region=us-central1

# 4. Vérifier la santé
curl https://tshiakani-vtc-backend-xxxxx.run.app/health
```

### Base de Données Non Accessible

```bash
# 1. Vérifier le statut de l'instance
gcloud sql instances describe tshiakani-vtc-db

# 2. Vérifier les opérations
gcloud sql operations list --instance=tshiakani-vtc-db

# 3. Vérifier les connexions
gcloud sql connect tshiakani-vtc-db --user=postgres

# 4. Redémarrer l'instance (si nécessaire)
gcloud sql instances restart tshiakani-vtc-db
```

### Redis Non Accessible

```bash
# 1. Vérifier le statut de l'instance
gcloud redis instances describe tshiakani-vtc-redis --region=us-central1

# 2. Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list --region=us-central1

# 3. Vérifier la configuration Cloud Run
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.vpcAccess)"

# 4. Redémarrer le service (si nécessaire)
gcloud run services update tshiakani-vtc-backend --region=us-central1
```

---

## 📚 Documentation de Référence

### Guides de Dépannage
- `GCP_POINTS_ATTENTION.md` - Points d'attention détaillés
- `GCP_ORDRE_EXECUTION.md` - Ordre d'exécution
- `GCP_PROCHAINES_ACTIONS.md` - Actions à effectuer

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore
- `GCP_SETUP_ETAPE4.md` - Cloud Run
- `GCP_SETUP_ETAPE5.md` - Monitoring

---

## 🎯 Résumé

### Problèmes Courants
1. **Instance Cloud SQL non accessible** - Vérifier le statut et les permissions
2. **Instance Memorystore non accessible** - Vérifier le VPC Connector
3. **Déploiement Cloud Run échoué** - Vérifier l'image et les permissions
4. **Connexion Redis échouée** - Vérifier le VPC Connector
5. **Calcul d'itinéraire échoué** - Vérifier la clé API et les quotas
6. **Variables d'environnement manquantes** - Configurer les variables
7. **Permissions IAM manquantes** - Ajouter les permissions
8. **Alertes non déclenchées** - Vérifier le monitoring

### Solutions d'Urgence
1. **Service hors ligne** - Vérifier le statut et redémarrer
2. **Base de données non accessible** - Vérifier le statut et redémarrer
3. **Redis non accessible** - Vérifier le VPC Connector et redémarrer

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide de dépannage rapide

