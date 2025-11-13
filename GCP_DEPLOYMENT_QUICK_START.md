# 🚀 Guide de Démarrage Rapide - Déploiement GCP

## 📋 Vue d'Ensemble

Ce guide vous permet de déployer rapidement le backend Tshiakani VTC sur Google Cloud Platform.

---

## ⚡ Déploiement en 3 Étapes

### Étape 1: Initialisation GCP

```bash
# Créer le projet GCP et activer les APIs
./scripts/gcp-setup-etape1.sh
```

### Étape 2: Configuration Cloud SQL

```bash
# Créer l'instance Cloud SQL
./scripts/gcp-create-cloud-sql.sh

# Vérifier la configuration
./scripts/gcp-verify-cloud-sql.sh
```

### Étape 3: Configuration Redis

```bash
# Créer l'instance Redis
./scripts/gcp-create-redis.sh

# Vérifier la configuration
./scripts/gcp-verify-redis.sh
```

### Étape 4: Déploiement Backend

```bash
# Déployer le backend sur Cloud Run
./scripts/gcp-deploy-backend.sh

# Configurer les variables d'environnement
./scripts/gcp-set-cloud-run-env.sh

# Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

---

## 🔧 Configuration Requise

### Prérequis

1. **gcloud CLI** installé et configuré
2. **Docker** installé
3. **Projet GCP** créé
4. **Facturation** activée

### Variables d'Environnement

Définissez ces variables avant d'exécuter les scripts :

```bash
export GCP_PROJECT_ID="tshiakani-vtc"
export GCP_REGION="us-central1"
export CLOUD_RUN_SERVICE_NAME="tshiakani-vtc-backend"
export REDIS_INSTANCE_NAME="tshiakani-vtc-redis"
export CLOUD_SQL_INSTANCE_NAME="tshiakani-vtc-db"
```

---

## 📝 Checklist de Déploiement

### Avant le Déploiement

- [ ] Projet GCP créé
- [ ] Facturation activée
- [ ] APIs activées (Cloud Run, Cloud SQL, Memorystore)
- [ ] gcloud CLI configuré
- [ ] Docker installé
- [ ] Variables d'environnement définies

### Déploiement

- [ ] Étape 1: Initialisation GCP complétée
- [ ] Étape 2: Cloud SQL configuré
- [ ] Étape 3: Redis configuré
- [ ] Étape 4: Backend déployé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Health check fonctionne

### Post-Déploiement

- [ ] Tests de connexion réussis
- [ ] Logs vérifiés
- [ ] Monitoring configuré
- [ ] Documentation mise à jour

---

## 🔍 Vérification

### Vérifier le Déploiement

```bash
# Vérifier tous les services
./scripts/gcp-verify-cloud-run.sh

# Vérifier Cloud SQL
./scripts/gcp-verify-cloud-sql.sh

# Vérifier Redis
./scripts/gcp-verify-redis.sh
```

### Tester le Backend

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region us-central1 \
  --format "value(status.url)")

# Tester le health check
curl $SERVICE_URL/health
```

---

## 🚨 Dépannage

### Erreur: "Project not found"

```bash
# Vérifier le projet
gcloud projects list

# Définir le projet
gcloud config set project tshiakani-vtc
```

### Erreur: "API not enabled"

```bash
# Activer les APIs
./scripts/gcp-setup-etape1.sh
```

### Erreur: "Connection refused"

```bash
# Vérifier les permissions IAM
./scripts/gcp-set-cloud-run-env.sh
```

---

## 📚 Documentation Complète

- **Étape 1**: `GCP_SETUP_ETAPE1.md`
- **Étape 2**: `GCP_SETUP_ETAPE2.md` (à créer)
- **Étape 3**: `GCP_SETUP_ETAPE3.md`
- **Étape 4**: `GCP_SETUP_ETAPE4.md`

---

## 🎯 Prochaines Étapes

Une fois le backend déployé :

1. **Dashboard Admin**: Configurer et déployer
2. **Applications iOS**: Configurer les URLs d'API
3. **Tests**: Tests end-to-end
4. **Monitoring**: Configurer les alertes

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

