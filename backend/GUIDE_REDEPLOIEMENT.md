# 🚀 Guide de Redéploiement du Backend

## ⚠️ Problèmes Actuels

1. **Compte de facturation non activé** : Le projet GCP nécessite un compte de facturation pour utiliser Cloud Build
2. **Docker non démarré** : Docker Desktop n'est pas en cours d'exécution

## ✅ Solutions

### Option 1 : Activer le Compte de Facturation (Recommandé)

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/billing?project=tshiakani-vtc-99cea)
2. Sélectionner ou créer un compte de facturation
3. Lier le compte au projet `tshiakani-vtc-99cea`
4. Relancer le déploiement :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   ./scripts/deploy-cloud-run.sh
   ```

### Option 2 : Déploiement avec Docker Local

1. **Démarrer Docker Desktop** :
   - Ouvrir Docker Desktop depuis Applications
   - Attendre que Docker soit complètement démarré

2. **Builder et pousser l'image** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   
   PROJECT_ID="tshiakani-vtc-99cea"
   IMAGE_NAME="gcr.io/${PROJECT_ID}/tshiakani-vtc-api"
   
   # Builder l'image
   docker build -t ${IMAGE_NAME} .
   
   # Configurer Docker pour GCR
   gcloud auth configure-docker
   
   # Pousser l'image
   docker push ${IMAGE_NAME}
   ```

3. **Déployer sur Cloud Run** :
   ```bash
   SERVICE_NAME="tshiakani-driver-backend"
   REGION="us-central1"
   JWT_SECRET="ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"
   ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
   CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
   
   ENV_VARS="NODE_ENV=production,PORT=8080,JWT_SECRET=${JWT_SECRET},ADMIN_API_KEY=${ADMIN_API_KEY},CORS_ORIGIN=${CORS_ORIGIN}"
   
   gcloud run deploy ${SERVICE_NAME} \
     --image ${IMAGE_NAME} \
     --platform managed \
     --region ${REGION} \
     --allow-unauthenticated \
     --memory 512Mi \
     --cpu 1 \
     --min-instances 1 \
     --max-instances 10 \
     --port 8080 \
     --set-env-vars "${ENV_VARS}"
   ```

### Option 3 : Déploiement via Cloud Console (Interface Web)

1. Aller sur [Cloud Run Console](https://console.cloud.google.com/run?project=tshiakani-vtc-99cea)
2. Cliquer sur "CREATE SERVICE" ou sélectionner le service existant
3. Utiliser l'image existante ou uploader une nouvelle
4. Configurer les variables d'environnement
5. Déployer

## 📋 Variables d'Environnement Requises

```bash
NODE_ENV=production
PORT=8080
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
```

## 🔍 Vérification du Déploiement

Après le déploiement, tester :

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(status.url)")

# Tester la route health
curl ${SERVICE_URL}/health

# Tester la route admin login
curl -X POST ${SERVICE_URL}/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

## 📝 Notes

- Le Dockerfile a été mis à jour pour utiliser le port 8080 (Cloud Run)
- Le service utilise `server.postgres.js` comme point d'entrée
- Les variables d'environnement peuvent être mises à jour après le déploiement via la console ou gcloud

