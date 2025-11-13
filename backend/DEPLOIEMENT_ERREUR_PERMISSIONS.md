# ⚠️ Erreur de Déploiement - Permissions et Facturation

## 🔍 Problème Rencontré

```
ERROR: (gcloud.builds.submit) The user is forbidden from accessing the bucket [tshiakani-vtc-99cea_cloudbuild]. 
Please check your organization's policy or if the user has the "serviceusage.services.use" permission.
```

## 📋 Diagnostic

### ✅ Permissions IAM
- **Statut** : ✅ **OK** - Vous avez le rôle `owner` sur le projet
- **Rôle** : `roles/owner`

### ❌ Facturation
- **Statut** : ❌ **NON ACTIVÉE** - `billingEnabled: false`
- **Problème** : La facturation est requise pour utiliser Cloud Build, Cloud Run, et Artifact Registry

### ❌ APIs Non Activées
- **Statut** : ❌ **NON ACTIVÉES** - Seulement `runtimeconfig.googleapis.com` est activé
- **APIs manquantes** :
  - `cloudbuild.googleapis.com` (Cloud Build)
  - `run.googleapis.com` (Cloud Run)
  - `artifactregistry.googleapis.com` (Artifact Registry)
  - `containerregistry.googleapis.com` (Container Registry)

---

## ✅ Solution : Activer la Facturation

### Étape 1 : Activer la Facturation dans Google Cloud Console

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Sélectionner le projet `tshiakani-vtc-99cea`
3. Aller dans **Facturation** > **Gérer les comptes de facturation**
4. Cliquer sur **Lier un compte de facturation**
5. Sélectionner ou créer un compte de facturation
6. Suivre les instructions pour activer la facturation
7. Attendre quelques minutes pour que la facturation soit activée

### Étape 2 : Vérifier l'Activation de la Facturation

```bash
# Vérifier que la facturation est activée
gcloud billing projects describe tshiakani-vtc-99cea

# Résultat attendu:
# billingEnabled: true
# billingAccountName: billingAccounts/XXXXXX-XXXXXX-XXXXXX
```

### Étape 3 : Activer les APIs Nécessaires

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

### Étape 4 : Vérifier l'Activation des APIs

```bash
# Vérifier que les APIs sont activées
gcloud services list --enabled --project=tshiakani-vtc-99cea | grep -E "cloudbuild|run|artifactregistry|containerregistry"
```

**Résultat attendu** :
```
cloudbuild.googleapis.com                 Cloud Build API
run.googleapis.com                        Cloud Run Admin API
artifactregistry.googleapis.com           Artifact Registry API
containerregistry.googleapis.com          Container Registry API
```

### Étape 5 : Redéployer le Backend

Une fois la facturation activée et les APIs activées, redéployez le backend :

```bash
cd backend
bash scripts/deploy-cloud-run.sh
```

---

## 💰 Coûts Estimés

### Configuration avec Upstash Redis (Recommandé - GRATUIT)

- **Upstash Redis** : **0 $/mois** (tier gratuit, 10k commandes/jour)
- **Cloud Run** : **0 $/mois** (tier gratuit jusqu'à 2 millions de requêtes/mois)
- **Cloud Build** : **0 $/mois** (tier gratuit jusqu'à 120 minutes/jour)
- **Container Registry** : **0 $/mois** (tier gratuit jusqu'à 0.5 Go)
- **Artifact Registry** : **0 $/mois** (tier gratuit jusqu'à 0.5 Go)

**Total** : **0 $/mois** (suffisant pour < 3000 clients)

### Configuration avec Redis Memorystore (Alternative)

- **Redis Memorystore** : **~30 $/mois** (tier basic, 1 GB)
- **Cloud Run** : **0 $/mois** (tier gratuit jusqu'à 2 millions de requêtes/mois)
- **Cloud Build** : **0 $/mois** (tier gratuit jusqu'à 120 minutes/jour)
- **Container Registry** : **0 $/mois** (tier gratuit jusqu'à 0.5 Go)
- **Artifact Registry** : **0 $/mois** (tier gratuit jusqu'à 0.5 Go)

**Total** : **~30 $/mois**

**Économies** : 30 $/mois (Redis Memorystore) → 0 $/mois (Upstash Redis)

---

## 📝 Note Importante

Même avec la facturation activée, les **tiers gratuits** de Google Cloud couvrent généralement les besoins d'un projet de développement ou MVP. Vous ne serez facturé que si vous dépassez les limites gratuites.

### Tiers Gratuits Google Cloud

- **Cloud Run** : 2 millions de requêtes/mois gratuites
- **Cloud Build** : 120 minutes de build/jour gratuites
- **Container Registry** : 0.5 Go de stockage gratuit
- **Artifact Registry** : 0.5 Go de stockage gratuit

**Pour un MVP avec < 3000 clients**, vous devriez rester dans les limites gratuites.

---

## 🔍 Vérification

### Vérifier la Facturation

```bash
# Vérifier si la facturation est activée
gcloud billing projects describe tshiakani-vtc-99cea

# Résultat attendu (une fois activée):
# billingEnabled: true
# billingAccountName: billingAccounts/XXXXXX-XXXXXX-XXXXXX
```

### Vérifier les APIs

```bash
# Vérifier que les APIs sont activées
gcloud services list --enabled --project=tshiakani-vtc-99cea | grep -E "cloudbuild|run|artifactregistry|containerregistry"
```

### Vérifier les Permissions

```bash
# Vérifier vos permissions sur le projet
gcloud projects get-iam-policy tshiakani-vtc-99cea \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud config get-value account)" \
  --format="table(bindings.role)"
```

---

## 📚 Documentation

### Guides Principaux

- **[REDEPLOIEMENT_FACTURATION.md](REDEPLOIEMENT_FACTURATION.md)** : Guide d'activation de la facturation
- **[PROCHAINES_ETAPES.md](PROCHAINES_ETAPES.md)** : Guide des prochaines étapes
- **[GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)** : Guide de configuration Upstash Redis

### Guides de Déploiement

- **[REDEPLOIEMENT_REDIS.md](REDEPLOIEMENT_REDIS.md)** : Guide de redéploiement avec Redis
- **[REDEPLOIEMENT_RESUME.md](REDEPLOIEMENT_RESUME.md)** : Résumé du redéploiement
- **[README.md](README.md)** : Documentation principale du backend

---

## ✅ Checklist

- [ ] **Facturation activée** dans Google Cloud Console
- [ ] **APIs Cloud Build activées** (`cloudbuild.googleapis.com`)
- [ ] **APIs Cloud Run activées** (`run.googleapis.com`)
- [ ] **APIs Artifact Registry activées** (`artifactregistry.googleapis.com`)
- [ ] **APIs Container Registry activées** (`containerregistry.googleapis.com`)
- [ ] **Vérification de la facturation** réussie
- [ ] **Vérification des APIs** réussie
- [ ] **Redéploiement du backend** réussi

---

## 🚀 Prochaines Étapes

Une fois la facturation activée et les APIs activées :

1. **Configurer Upstash Redis** (recommandé, gratuit) : Voir [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)
2. **Configurer REDIS_URL** dans `deploy-cloud-run.sh`
3. **Redéployer le backend** : `bash scripts/deploy-cloud-run.sh`
4. **Vérifier les logs** pour confirmer la connexion Redis
5. **Tester l'inscription avec OTP** depuis l'URL du service

---

## 🎉 Résumé

Le problème principal est que **la facturation n'est pas activée** dans GCP. Une fois la facturation activée et les APIs activées, vous pourrez redéployer le backend sans problème.

**Économies** : Utilisez **Upstash Redis** (gratuit) au lieu de Redis Memorystore (payant) pour réduire les coûts à **0 $/mois** pour < 3000 clients.

---

**Date** : 2025-11-12  
**Statut** : ⚠️ **EN ATTENTE DE FACTURATION**

