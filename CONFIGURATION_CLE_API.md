# 🔐 Configuration de la Clé API Admin

## 📋 Vue d'ensemble

Le système utilise une clé API pour sécuriser les routes admin (`/api/admin/*`). Cette clé doit être configurée à la fois dans le backend et le dashboard.

## 🔑 Clé API générée

Une clé API sécurisée a été générée pour vous :

```
aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

**⚠️ IMPORTANT** : Changez cette clé en production avec une nouvelle clé générée aléatoirement !

## 📝 Configuration Backend

### 1. Créer le fichier `.env`

Dans le dossier `backend/`, créez un fichier `.env` basé sur `.env.example` :

```bash
cd backend
cp .env.example .env
```

### 2. Configurer la clé API

Éditez le fichier `.env` et ajoutez :

```env
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 3. Vérifier la configuration

Le middleware `adminApiKeyAuth` vérifie automatiquement cette clé dans les headers `X-ADMIN-API-KEY` pour toutes les requêtes vers `/api/admin/*`.

## 📝 Configuration Dashboard

### 1. Créer le fichier `.env`

Dans le dossier `admin-dashboard/`, créez un fichier `.env` basé sur `.env.example` :

```bash
cd admin-dashboard
cp .env.example .env
```

### 2. Configurer la clé API

Éditez le fichier `.env` et ajoutez :

```env
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 3. Redémarrer le serveur de développement

Après avoir modifié le `.env`, redémarrez le serveur Vite :

```bash
npm run dev
```

## 🔄 Comment ça fonctionne

### Backend

Le middleware `adminApiKeyAuth` (dans `backend/middlewares.postgres/adminApiKey.js`) :

1. Récupère la clé API depuis le header `X-ADMIN-API-KEY`
2. Compare avec `process.env.ADMIN_API_KEY`
3. Autorise ou refuse la requête

### Dashboard

L'intercepteur Axios (dans `admin-dashboard/src/services/api.js`) :

1. Détecte les requêtes vers `/api/admin/*`
2. Ajoute automatiquement `X-ADMIN-API-KEY` dans les headers
3. Récupère la clé depuis `VITE_ADMIN_API_KEY` (env) ou `localStorage.getItem('admin_api_key')`

## 🔒 Générer une nouvelle clé API

Pour générer une nouvelle clé API sécurisée :

### Avec Node.js :
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Avec OpenSSL :
```bash
openssl rand -hex 32
```

### Avec Python :
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

## ✅ Vérification

### Test avec curl :

```bash
# Test sans clé API (doit échouer)
curl -X GET "http://localhost:3000/api/admin/stats" \
  -H "Authorization: Bearer <token>"
# Réponse attendue: 403 Forbidden

# Test avec clé API (doit réussir)
curl -X GET "http://localhost:3000/api/admin/stats" \
  -H "Authorization: Bearer <token>" \
  -H "X-ADMIN-API-KEY: aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
# Réponse attendue: 200 OK avec les statistiques
```

## 🚨 Sécurité en Production

1. **Changez la clé par défaut** : Ne gardez jamais la clé d'exemple en production
2. **Stockage sécurisé** : Utilisez des variables d'environnement, jamais de code en dur
3. **Rotation régulière** : Changez la clé périodiquement
4. **HTTPS uniquement** : En production, utilisez toujours HTTPS
5. **Logs** : Surveillez les tentatives d'accès avec des clés invalides

## 📚 Fichiers concernés

- `backend/.env.example` - Exemple de configuration backend
- `backend/middlewares.postgres/adminApiKey.js` - Middleware de vérification
- `admin-dashboard/.env.example` - Exemple de configuration dashboard
- `admin-dashboard/src/services/api.js` - Intercepteur Axios

## 🆘 Dépannage

### Erreur "Clé API admin manquante"

**Cause** : Le header `X-ADMIN-API-KEY` n'est pas envoyé.

**Solution** :
1. Vérifiez que `VITE_ADMIN_API_KEY` est défini dans `.env` du dashboard
2. Redémarrez le serveur de développement
3. Vérifiez les headers dans les DevTools du navigateur

### Erreur "Clé API admin invalide"

**Cause** : La clé dans le dashboard ne correspond pas à celle du backend.

**Solution** :
1. Vérifiez que `ADMIN_API_KEY` (backend) = `VITE_ADMIN_API_KEY` (dashboard)
2. Assurez-vous qu'il n'y a pas d'espaces ou de caractères invisibles
3. Redémarrez les deux serveurs

### Erreur "Configuration serveur manquante"

**Cause** : `ADMIN_API_KEY` n'est pas défini dans le `.env` du backend.

**Solution** :
1. Créez le fichier `.env` dans `backend/`
2. Ajoutez `ADMIN_API_KEY=...`
3. Redémarrez le serveur backend

