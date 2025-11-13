# 💳 Activer le Compte de Facturation

## ⚠️ Problème

Le compte de facturation n'est pas activé pour le projet `tshiakani-vtc-99cea`.

**Erreur** :
```
Billing account for project '502930620893' is not found. 
Billing must be enabled for activation of service(s)
```

---

## ✅ Solution : Activer le Compte de Facturation

### Option 1: Via Google Cloud Console (Recommandé)

1. **Allez sur Google Cloud Console** :
   - https://console.cloud.google.com/
   - Sélectionnez le projet `tshiakani-vtc-99cea`

2. **Activez la facturation** :
   - Allez dans **Facturation** > **Comptes de facturation**
   - Cliquez sur **Lier un compte de facturation**
   - Sélectionnez ou créez un compte de facturation
   - Confirmez la liaison

3. **Vérifiez** :
   - Le projet devrait maintenant avoir un compte de facturation lié
   - Les APIs peuvent être activées

### Option 2: Via gcloud CLI

```bash
# Lister les comptes de facturation disponibles
gcloud billing accounts list

# Lier un compte de facturation au projet
gcloud billing projects link tshiakani-vtc-99cea \
  --billing-account=BILLING_ACCOUNT_ID
```

**Remplacez `BILLING_ACCOUNT_ID`** par l'ID de votre compte de facturation.

---

## 📋 APIs Nécessaires

Une fois la facturation activée, activez ces APIs :

```bash
# Cloud Build API
gcloud services enable cloudbuild.googleapis.com --project=tshiakani-vtc-99cea

# Cloud Run API
gcloud services enable run.googleapis.com --project=tshiakani-vtc-99cea

# Container Registry API
gcloud services enable containerregistry.googleapis.com --project=tshiakani-vtc-99cea

# Artifact Registry API
gcloud services enable artifactregistry.googleapis.com --project=tshiakani-vtc-99cea
```

---

## 💰 Coûts Estimés

### Cloud Run (Gratuit jusqu'à certaines limites)

- **2 millions de requêtes/mois** : Gratuit
- **400 000 GB-secondes** : Gratuit
- **200 000 vCPU-secondes** : Gratuit
- Au-delà : Payant selon l'utilisation

### Cloud Build

- **120 minutes/jour** : Gratuit
- Au-delà : ~$0.003/minute

### Container Registry

- **0.5 GB de stockage** : Gratuit
- Au-delà : ~$0.026/GB/mois

---

## 🚀 Après Activation

Une fois la facturation activée :

1. **Activer les APIs** (voir ci-dessus)
2. **Déployer le backend** :
   ```bash
   cd backend
   ./scripts/deploy-cloud-run.sh
   ```
3. **Tester l'authentification**

---

## 📝 Note

Si vous n'avez pas de compte de facturation :

1. Créez-en un sur https://console.cloud.google.com/billing
2. Ajoutez une méthode de paiement
3. Liez-le au projet

---

**Date** : $(date)
**Statut** : ⚠️ En attente d'activation de la facturation

