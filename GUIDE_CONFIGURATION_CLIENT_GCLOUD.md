# 📱 Guide de Configuration - App Client vers Backend Google Cloud

Ce guide explique comment configurer l'application client iOS pour qu'elle se connecte au backend déployé sur Google Cloud.

---

## 🎯 Objectif

Configurer l'application client pour qu'elle utilise le backend déployé sur Google Cloud Run au lieu du backend local.

---

## 📋 Prérequis

1. ✅ Backend déployé sur Google Cloud Run
2. ✅ URL du backend Cloud Run disponible
3. ✅ CORS configuré sur le backend pour accepter les requêtes de l'app iOS
4. ✅ Projet Xcode ouvert

---

## 🔍 Étape 1: Obtenir l'URL du Backend Déployé

### Option A: Via Google Cloud Console

1. Allez dans [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet: `tshiakani-vtc`
3. Allez dans **Cloud Run** > **Services**
4. Cliquez sur votre service: `tshiakani-vtc-api`
5. Copiez l'URL du service (format: `https://tshiakani-vtc-api-xxxxx.run.app`)

### Option B: Via gcloud CLI

```bash
# Obtenir l'URL du service déployé
gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format "value(status.url)"
```

### Option C: Après le Déploiement

Après avoir déployé le backend, l'URL est affichée dans la sortie:

```bash
cd backend
./scripts/deploy-cloud-run.sh
```

Vous verrez:
```
✅ Déploiement terminé!
🌐 URL du service: https://tshiakani-vtc-api-us-central1-tshiakani-vtc.a.run.app
```

---

## 🔧 Étape 2: Configurer l'Application iOS

### 2.1 Mettre à jour Info.plist

Ouvrez `Tshiakani VTC/Info.plist` et mettez à jour les URLs:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_BASE_URL</key>
	<string>https://VOTRE-URL-CLOUD-RUN.run.app/api</string>
	<key>WS_BASE_URL</key>
	<string>https://VOTRE-URL-CLOUD-RUN.run.app</string>
</dict>
</plist>
```

**Remplacez `VOTRE-URL-CLOUD-RUN.run.app` par l'URL réelle de votre backend Cloud Run.**

### 2.2 Vérifier ConfigurationService.swift

Le fichier `Tshiakani VTC/Services/ConfigurationService.swift` est déjà configuré pour:
- ✅ Lire les URLs depuis `Info.plist` en priorité
- ✅ Utiliser `localhost:3000` en mode DEBUG
- ✅ Utiliser les URLs de production en mode RELEASE

**Aucune modification nécessaire** si `Info.plist` est correctement configuré.

---

## 🌐 Étape 3: Configurer CORS sur le Backend

Le backend doit accepter les requêtes de l'application iOS. Vérifiez la configuration CORS:

### 3.1 Vérifier server.postgres.js

Le fichier `backend/server.postgres.js` doit avoir la configuration CORS suivante:

```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN || ["http://localhost:3001", "http://localhost:5173"],
  credentials: true
}));
```

### 3.2 Configurer CORS pour Production

Lors du déploiement sur Cloud Run, configurez la variable d'environnement `CORS_ORIGIN`:

```bash
# Déployer avec CORS configuré pour l'app iOS
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --set-env-vars "CORS_ORIGIN=*" \
  --allow-unauthenticated
```

**Note**: Pour la production, vous pouvez utiliser `*` pour accepter toutes les origines, ou spécifier des origines spécifiques pour plus de sécurité.

### 3.3 Configuration CORS Sécurisée (Recommandé)

Pour une configuration plus sécurisée, spécifiez les origines autorisées:

```bash
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --set-env-vars "CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app" \
  --allow-unauthenticated
```

---

## 🔐 Étape 4: Configuration WebSocket

### 4.1 URL WebSocket

L'URL WebSocket doit utiliser `https://` (pas `wss://`) car Socket.io gère automatiquement la sécurisation.

Dans `Info.plist`:
```xml
<key>WS_BASE_URL</key>
<string>https://VOTRE-URL-CLOUD-RUN.run.app</string>
```

### 4.2 Vérifier la Configuration Socket.io

Le backend doit être configuré pour accepter les connexions WebSocket. Vérifiez `backend/server.postgres.js`:

```javascript
const io = socketIo(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || ["http://localhost:3001", "http://localhost:5173"],
    methods: ["GET", "POST"]
  }
});
```

---

## 🧪 Étape 5: Tester la Connexion

### 5.1 Tester l'API REST

```bash
# Tester l'endpoint health
curl https://VOTRE-URL-CLOUD-RUN.run.app/health

# Tester l'endpoint d'authentification
curl -X POST https://VOTRE-URL-CLOUD-RUN.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "role": "client"
  }'
```

### 5.2 Tester depuis l'App iOS

1. **Mode DEBUG**: L'app utilise `localhost:3000` (backend local)
2. **Mode RELEASE**: L'app utilise l'URL configurée dans `Info.plist`

Pour tester avec le backend Cloud Run en mode DEBUG, vous pouvez:
- Modifier temporairement `ConfigurationService.swift` pour forcer l'URL de production
- Ou utiliser `UserDefaults` pour override l'URL:

```swift
// Dans l'application (pour test uniquement)
UserDefaults.standard.set("https://VOTRE-URL-CLOUD-RUN.run.app/api", forKey: "api_base_url")
UserDefaults.standard.set("https://VOTRE-URL-CLOUD-RUN.run.app", forKey: "socket_base_url")
```

---

## 📝 Étape 6: Configuration des Variables d'Environnement

### 6.1 Variables Requises sur Cloud Run

Lors du déploiement, assurez-vous que les variables suivantes sont configurées:

```bash
gcloud run deploy tshiakani-vtc-api \
  --set-env-vars "NODE_ENV=production" \
  --set-env-vars "CORS_ORIGIN=*" \
  --set-env-vars "PORT=8080"
```

### 6.2 Secrets (Recommandé)

Pour les valeurs sensibles, utilisez Secret Manager:

```bash
# Créer les secrets
echo -n "votre-jwt-secret" | gcloud secrets create jwt-secret --data-file=-
echo -n "votre-admin-api-key" | gcloud secrets create admin-api-key --data-file=-
echo -n "votre-db-password" | gcloud secrets create database-password --data-file=-

# Déployer avec les secrets
gcloud run deploy tshiakani-vtc-api \
  --set-secrets "JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest,DB_PASSWORD=database-password:latest"
```

---

## 🔍 Étape 7: Vérification

### 7.1 Vérifier la Configuration

1. ✅ `Info.plist` contient les bonnes URLs
2. ✅ `ConfigurationService.swift` lit les URLs depuis `Info.plist`
3. ✅ CORS est configuré sur le backend
4. ✅ Backend est déployé et accessible
5. ✅ WebSocket est configuré correctement

### 7.2 Tester la Connexion

1. **Build l'app en mode RELEASE**
2. **Lancer l'app**
3. **Vérifier les logs** pour confirmer la connexion au backend Cloud Run
4. **Tester l'authentification**
5. **Tester les WebSockets**

---

## 🛠️ Dépannage

### Problème: L'app ne se connecte pas au backend

**Solutions**:
1. Vérifier que l'URL dans `Info.plist` est correcte
2. Vérifier que le backend est accessible: `curl https://VOTRE-URL-CLOUD-RUN.run.app/health`
3. Vérifier les logs du backend: `gcloud run services logs read tshiakani-vtc-api`
4. Vérifier CORS configuration

### Problème: Erreurs CORS

**Solutions**:
1. Vérifier que `CORS_ORIGIN` est configuré sur Cloud Run
2. Vérifier que l'origine de la requête est autorisée
3. Vérifier les headers CORS dans la réponse

### Problème: WebSocket ne se connecte pas

**Solutions**:
1. Vérifier que l'URL WebSocket est correcte (utilisez `https://` pas `wss://`)
2. Vérifier que Socket.io est configuré sur le backend
3. Vérifier les logs du backend pour les erreurs de connexion
4. Vérifier que les namespaces sont corrects (`/ws/client`, `/ws/driver`)

### Problème: Timeout des requêtes

**Solutions**:
1. Vérifier que le backend répond dans les temps
2. Augmenter le timeout dans `ConfigurationService.swift`
3. Vérifier la configuration Cloud Run (memory, CPU)

---

## 📚 Ressources

- [Documentation Cloud Run](https://cloud.google.com/run/docs)
- [Documentation CORS](https://developer.mozilla.org/fr/docs/Web/HTTP/CORS)
- [Documentation Socket.io](https://socket.io/docs/v4/)
- [Guide de Déploiement](./GUIDE_DEPLOIEMENT_FIREBASE_GCP.md)

---

## ✅ Checklist

- [ ] Backend déployé sur Cloud Run
- [ ] URL du backend obtenue
- [ ] `Info.plist` mis à jour avec les bonnes URLs
- [ ] CORS configuré sur le backend
- [ ] WebSocket configuré correctement
- [ ] Variables d'environnement configurées
- [ ] Secrets configurés (si nécessaire)
- [ ] Tests de connexion effectués
- [ ] App iOS testée en mode RELEASE

---

**Dernière mise à jour**: $(date)

