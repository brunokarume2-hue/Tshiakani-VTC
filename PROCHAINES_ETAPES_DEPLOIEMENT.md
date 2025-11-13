# 🚀 Prochaines Étapes - Déploiement Backend

## ⚠️ Situation Actuelle

### Problème de Facturation

Le projet `tshiakani-vtc-99cea` nécessite un compte de facturation, mais :
- Le compte de facturation disponible a un **quota dépassé**
- Impossible de lier le compte au projet actuellement

### Backend Existant

Le backend est déjà déployé sur :
- **URL** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **Health check** : ✅ Fonctionne
- **Routes auth** : ❌ Non disponibles (`Cannot POST /api/auth/admin/login`)

---

## ✅ Solutions

### Option 1: Augmenter le Quota de Facturation (Recommandé)

1. **Allez sur Google Cloud Console** :
   - https://console.cloud.google.com/billing
   - Sélectionnez le compte de facturation `01A0D2-26A848-5DC5B9`

2. **Demander une augmentation de quota** :
   - Allez dans **Quotas**
   - Recherchez les quotas Cloud Build / Cloud Run
   - Demandez une augmentation

3. **Ou contactez le support** :
   - https://support.google.com/code/contact/billing_quota_increase

### Option 2: Utiliser un Autre Projet

Si un autre projet a la facturation activée :

```bash
# Changer de projet
gcloud config set project AUTRE_PROJET_ID

# Déployer le backend
cd backend
./scripts/deploy-cloud-run.sh
```

### Option 3: Redéployer le Backend Existant

Le backend est déjà déployé mais les routes ne fonctionnent pas. Il faut :

1. **Identifier le projet où il est déployé**
2. **Redéployer avec les routes d'authentification**
3. **Ou mettre à jour le service existant**

### Option 4: Utiliser Google Cloud Console

1. **Allez sur** : https://console.cloud.google.com/
2. **Sélectionnez le projet** avec facturation activée
3. **Allez dans Cloud Build** > **Triggers**
4. **Créez un trigger** qui utilise `cloudbuild.yaml`
5. **Déclenchez le build**

---

## 🔍 Vérifications à Faire

### 1. Identifier le Projet du Backend Existant

Le backend `tshiakani-driver-backend-n55z6qh7la-uc.a.run.app` est déployé sur un projet. Il faut identifier lequel :

```bash
# Lister tous les services Cloud Run
gcloud run services list --platform managed --format="table(metadata.name,status.url)"

# Ou vérifier dans Google Cloud Console
# Cloud Run > Services > tshiakani-driver-backend
```

### 2. Vérifier les Routes Disponibles

```bash
# Tester les routes
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

### 3. Mettre à Jour le Service Existant

Si le backend est déjà déployé, il faut le mettre à jour :

```bash
# Identifier le projet
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format="value(metadata.namespace)"

# Mettre à jour avec la nouvelle image
gcloud run services update tshiakani-driver-backend \
  --image gcr.io/PROJECT_ID/tshiakani-vtc-api \
  --region us-central1
```

---

## 📋 Checklist

- [ ] Résoudre le problème de facturation (quota ou nouveau compte)
- [ ] Activer les APIs nécessaires
- [ ] Identifier le projet du backend existant
- [ ] Builder la nouvelle image Docker
- [ ] Déployer ou mettre à jour le backend
- [ ] Tester la route `/api/auth/admin/login`
- [ ] Tester la route `/api/auth/signin`
- [ ] Vérifier que le dashboard peut se connecter
- [ ] Vérifier que l'app iOS peut se connecter

---

## 🎯 Actions Immédiates

1. **Résoudre la facturation** :
   - Augmenter le quota OU
   - Utiliser un autre projet avec facturation

2. **Une fois la facturation résolue** :
   ```bash
   # Activer les APIs
   gcloud services enable cloudbuild.googleapis.com --project=tshiakani-vtc-99cea
   gcloud services enable run.googleapis.com --project=tshiakani-vtc-99cea
   
   # Déployer
   cd backend
   ./scripts/deploy-cloud-run.sh
   ```

3. **Tester** :
   ```bash
   # Route admin/login
   curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber":"+243900000000"}'
   ```

---

**Date** : $(date)
**Statut** : ⚠️ En attente de résolution de la facturation
