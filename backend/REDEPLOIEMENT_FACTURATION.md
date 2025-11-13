# ⚠️ Facturation Requise - Redéploiement Backend

## 🚨 Problème Rencontré

```
ERROR: Billing account for project '502930620893' is not found. 
Billing must be enabled for activation of service(s) 'cloudbuild.googleapis.com,run.googleapis.com,...' to proceed.
```

## 🔍 Cause

Le projet GCP `tshiakani-vtc-99cea` n'a pas de **compte de facturation** activé. Les services suivants nécessitent la facturation :

- **Cloud Build** (`cloudbuild.googleapis.com`)
- **Cloud Run** (`run.googleapis.com`)
- **Artifact Registry** (`artifactregistry.googleapis.com`)
- **Container Registry** (`containerregistry.googleapis.com`)

## ✅ Solution : Activer la Facturation

### Étape 1 : Activer la Facturation dans Google Cloud Console

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Sélectionner le projet `tshiakani-vtc-99cea`
3. Aller dans **Facturation** > **Gérer les comptes de facturation**
4. Cliquer sur **Lier un compte de facturation**
5. Sélectionner ou créer un compte de facturation
6. Suivre les instructions pour activer la facturation

### Étape 2 : Activer les APIs Nécessaires

Une fois la facturation activée, activez les APIs nécessaires :

```bash
# Activer les APIs nécessaires
gcloud services enable cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=tshiakani-vtc-99cea
```

### Étape 3 : Vérifier l'Activation

```bash
# Vérifier que les APIs sont activées
gcloud services list --enabled --project=tshiakani-vtc-99cea | grep -E "cloudbuild|run|artifactregistry|containerregistry"
```

### Étape 4 : Redéployer le Backend

```bash
cd backend
bash scripts/deploy-cloud-run.sh
```

## 💰 Coûts Estimés

### Cloud Run

- **Tier gratuit** : 2 millions de requêtes/mois
- **Mémoire** : 512 Mi (gratuit jusqu'à 2 Gi)
- **CPU** : 1 vCPU (gratuit jusqu'à 2 vCPU)
- **Coût estimé** : **GRATUIT** pour les premiers 2 millions de requêtes/mois

### Cloud Build

- **Tier gratuit** : 120 minutes de build/jour
- **Coût estimé** : **GRATUIT** jusqu'à 120 minutes/jour

### Container Registry / Artifact Registry

- **Stockage** : 0.5 Go gratuit
- **Coût estimé** : **GRATUIT** jusqu'à 0.5 Go

### Redis Memorystore (si activé - Alternative payante)

- **Tier basic** : ~$30/mois pour 1 Go
- **Coût estimé** : ~$30/mois

### Upstash Redis (Recommandé - GRATUIT)

- **Tier gratuit** : 10 000 commandes/jour, 256 MB de stockage
- **Coût estimé** : **0 $/mois** (suffisant pour < 3000 clients)

## 📋 Checklist

- [ ] Compte de facturation activé dans GCP
- [ ] APIs Cloud Build activées
- [ ] APIs Cloud Run activées
- [ ] APIs Artifact Registry activées
- [ ] APIs Container Registry activées
- [ ] Vérification des APIs activées
- [ ] Redéploiement du backend

## 🔍 Vérification de la Facturation

```bash
# Vérifier si la facturation est activée
gcloud billing accounts list

# Vérifier le compte de facturation lié au projet
gcloud billing projects describe tshiakani-vtc-99cea
```

## 📝 Note Importante

Même avec la facturation activée, les **tiers gratuits** de Google Cloud couvrent généralement les besoins d'un projet de développement ou MVP. Vous ne serez facturé que si vous dépassez les limites gratuites.

## 🚀 Alternative : Déploiement Local avec Docker

Si vous ne souhaitez pas activer la facturation pour le moment, vous pouvez :

1. **Développer localement** avec Redis installé localement
2. **Tester localement** avec `npm run dev`
3. **Utiliser un service de déploiement gratuit** comme Render.com ou Railway.app

---

**Date** : 2025-11-12  
**Statut** : ⚠️ **FACTURATION REQUISE**

