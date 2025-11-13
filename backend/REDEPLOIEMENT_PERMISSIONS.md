# ⚠️ Problème de Permissions - Redéploiement Backend

## 🚨 Erreur Rencontrée

```
ERROR: (gcloud.builds.submit) The user is forbidden from accessing the bucket [tshiakani-vtc-99cea_cloudbuild]. 
Please check your organization's policy or if the user has the "serviceusage.services.use" permission.
```

## 🔍 Cause

L'utilisateur `brunokarume@gmail.com` n'a pas les permissions nécessaires pour :
- Accéder au bucket Cloud Build
- Utiliser le service Cloud Build
- Déployer sur Cloud Run

## ✅ Solutions

### Solution 1 : Demander les Permissions Nécessaires

Contactez l'administrateur du projet GCP pour obtenir les rôles suivants :

1. **Cloud Build Editor** ou **Cloud Build Admin**
   ```bash
   gcloud projects add-iam-policy-binding tshiakani-vtc-99cea \
     --member="user:brunokarume@gmail.com" \
     --role="roles/cloudbuild.builds.editor"
   ```

2. **Service Usage Consumer**
   ```bash
   gcloud projects add-iam-policy-binding tshiakani-vtc-99cea \
     --member="user:brunokarume@gmail.com" \
     --role="roles/serviceusage.serviceUsageConsumer"
   ```

3. **Cloud Run Admin** ou **Cloud Run Developer**
   ```bash
   gcloud projects add-iam-policy-binding tshiakani-vtc-99cea \
     --member="user:brunokarume@gmail.com" \
     --role="roles/run.admin"
   ```

4. **Storage Admin** (pour le bucket Cloud Build)
   ```bash
   gcloud projects add-iam-policy-binding tshiakani-vtc-99cea \
     --member="user:brunokarume@gmail.com" \
     --role="roles/storage.admin"
   ```

### Solution 2 : Utiliser Docker Local + Cloud Run Deploy

Si vous avez Docker installé localement, vous pouvez builder l'image localement et la pousser vers Container Registry :

```bash
# 1. Builder l'image Docker localement
cd backend
docker build -t gcr.io/tshiakani-vtc-99cea/tshiakani-vtc-api:latest .

# 2. Configurer Docker pour utiliser gcloud comme credential helper
gcloud auth configure-docker

# 3. Pousser l'image vers Container Registry
docker push gcr.io/tshiakani-vtc-99cea/tshiakani-vtc-api:latest

# 4. Déployer sur Cloud Run
gcloud run deploy tshiakani-driver-backend \
  --image gcr.io/tshiakani-vtc-99cea/tshiakani-vtc-api:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production,PORT=8080,JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab,ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8,CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,TWILIO_ACCOUNT_SID=TWILIO_ACCOUNT_SID,TWILIO_AUTH_TOKEN=TWILIO_AUTH_TOKEN,TWILIO_WHATSAPP_FROM=whatsapp:+14155238886,TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75"
```

### Solution 3 : Utiliser GitHub Actions ou Cloud Build Triggers

Si vous avez un dépôt Git configuré, vous pouvez utiliser GitHub Actions ou Cloud Build Triggers pour automatiser le déploiement :

1. **GitHub Actions** : Configurer un workflow GitHub Actions pour builder et déployer automatiquement
2. **Cloud Build Triggers** : Configurer un trigger Cloud Build qui se déclenche lors d'un push sur Git

### Solution 4 : Utiliser Google Cloud Console

Vous pouvez aussi déployer manuellement via Google Cloud Console :

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Sélectionner le projet `tshiakani-vtc-99cea`
3. Aller dans **Cloud Run** > **Services**
4. Cliquer sur **Créer un service** ou **Modifier** le service existant
5. Configurer les variables d'environnement
6. Déployer

## 📋 Checklist des Permissions

- [ ] Cloud Build Editor ou Admin
- [ ] Service Usage Consumer
- [ ] Cloud Run Admin ou Developer
- [ ] Storage Admin (pour le bucket Cloud Build)
- [ ] Artifact Registry Writer (si vous utilisez Artifact Registry)

## 🔍 Vérification des Permissions

```bash
# Vérifier les permissions actuelles
gcloud projects get-iam-policy tshiakani-vtc-99cea \
  --flatten="bindings[].members" \
  --filter="bindings.members:brunokarume@gmail.com" \
  --format="table(bindings.role)"
```

## 📝 Note Importante

Pour la production, il est recommandé d'utiliser **Secret Manager** pour stocker les valeurs sensibles comme :
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `JWT_SECRET`
- `ADMIN_API_KEY`

Au lieu de les mettre directement dans les variables d'environnement.

---

**Date** : 2025-11-12  
**Statut** : ⚠️ **PERMISSIONS REQUISES**

