# 🚀 Actions Nécessaires pour Redéployer le Backend

## ⚠️ Problèmes Identifiés

1. **Compte de facturation non activé** : Le projet GCP nécessite un compte de facturation pour activer les APIs
2. **APIs non activées** : Cloud Run API, Cloud Build API, Container Registry API

## ✅ Actions à Effectuer

### Étape 1 : Activer le Compte de Facturation

1. Aller sur : https://console.cloud.google.com/billing?project=tshiakani-vtc-99cea
2. Sélectionner ou créer un compte de facturation
3. Lier le compte au projet

**Note** : Google Cloud offre un crédit gratuit de $300 pour les nouveaux comptes

### Étape 2 : Activer les APIs Nécessaires

Une fois le compte de facturation activé, activer les APIs :

**Option A : Via la Console Web**
- Cloud Run API : https://console.developers.google.com/apis/api/run.googleapis.com/overview?project=tshiakani-vtc-99cea
- Cloud Build API : https://console.developers.google.com/apis/api/cloudbuild.googleapis.com/overview?project=tshiakani-vtc-99cea
- Container Registry API : https://console.developers.google.com/apis/api/containerregistry.googleapis.com/overview?project=tshiakani-vtc-99cea

**Option B : Via la ligne de commande** (après activation du compte de facturation)
```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  containerregistry.googleapis.com \
  --project=tshiakani-vtc-99cea
```

### Étape 3 : Redéployer le Backend

Une fois les APIs activées :

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"
./scripts/deploy-cloud-run.sh
```

## 📋 Informations du Projet

- **Project ID** : `tshiakani-vtc-99cea`
- **Service Name** : `tshiakani-driver-backend`
- **Region** : `us-central1`
- **Port** : `8080` (mis à jour dans Dockerfile)

## 🔧 Modifications Effectuées

✅ **Dockerfile mis à jour** : Port changé de 3000 à 8080 pour Cloud Run

## 📝 Variables d'Environnement

Les variables suivantes seront configurées automatiquement par le script :
- `NODE_ENV=production`
- `PORT=8080`
- `JWT_SECRET` (défini dans le script)
- `ADMIN_API_KEY` (défini dans le script)
- `CORS_ORIGIN` (défini dans le script)

## ⏱️ Temps Estimé

- Activation du compte de facturation : 5-10 minutes
- Activation des APIs : 2-5 minutes
- Build et déploiement : 10-15 minutes

**Total** : ~20-30 minutes

